require "set"

class ShoppingListBuilder
  def initialize(user, recipe)
    @user = user
    @recipe = recipe
    @errors = []
  end

  def build
    ActiveRecord::Base.transaction do
      validate_inputs
      raise StandardError, @errors.join(", ") if @errors.any?

      list = create_shopping_list
      add_items_from_recipe(list)
      list
    end
  rescue ActiveRecord::RecordInvalid => e
    raise StandardError, "買い物リストの作成に失敗しました: #{e.message}"
  rescue => e
    raise StandardError, "買い物リストの作成中にエラーが発生しました: #{e.message}"
  end

  private

  def validate_inputs
    @errors << "ユーザーが指定されていません" unless @user
    @errors << "レシピが指定されていません" unless @recipe
    if @recipe && !@recipe.recipe_ingredients.exists?
      @errors << "レシピに材料が含まれていません"
    end
  end

  def create_shopping_list
    @user.shopping_lists.create!(
      recipe: @recipe,
      status: :pending,
      title: "#{@recipe.title}の買い物リスト"
    )
  end

  def add_items_from_recipe(list)
    missing_ingredients = calculate_missing_ingredients

    missing_ingredients.each do |ingredient_data|
      item_params = {
        ingredient_id: ingredient_data[:ingredient_id],
        quantity: ingredient_data[:quantity],
        unit: ingredient_data[:unit]
      }

      # ingredient_idがnullの場合はingredient_nameを設定
      if ingredient_data[:ingredient_id].nil? && ingredient_data[:ingredient_name].present?
        item_params[:ingredient_name] = ingredient_data[:ingredient_name]
      end

      if should_mark_as_checked?(ingredient_data)
        item_params[:is_checked] = true
        item_params[:checked_at] = Time.current
      end

      list.shopping_list_items.create!(item_params)
    end
  end

  def calculate_missing_ingredients
    missing_ingredients = []
    user_inventory = build_user_inventory

    @recipe.recipe_ingredients.includes(:ingredient).each do |recipe_ingredient|
      next if recipe_ingredient.is_optional?

      ingredient = recipe_ingredient.ingredient
      original_amount = recipe_ingredient.amount
      required_amount = ensure_required_amount(original_amount)
      require_exact_amount = original_amount.present? && original_amount.to_f > 0
      recipe_unit = recipe_ingredient.unit

      if ingredient
        ingredient_unit = ingredient.unit

        shortage_amount = 0
        final_unit = "適量"

        if require_exact_amount
          # レシピ単位を在庫単位（基準単位）に変換
          converted_required_amount = convert_to_base_unit(required_amount, recipe_unit, ingredient_unit)
          available_amount = user_inventory[ingredient.id] || 0

          if converted_required_amount.nil?
            # 変換失敗時は在庫チェックをスキップしてレシピ量をそのまま使用
            log_conversion_warning(ingredient.name, recipe_unit, ingredient_unit)
            shortage_amount = required_amount
            # 変換失敗時の単位決定：レシピ単位が許可されていれば使用、なければ在庫単位
            final_unit = if recipe_unit.present? && ShoppingListItem::ALLOWED_UNITS.include?(recipe_unit)
              recipe_unit
            elsif ingredient_unit.present? && ShoppingListItem::ALLOWED_UNITS.include?(ingredient_unit)
              ingredient_unit
            else
              "個"
            end
          else
            # 在庫単位で不足量を計算
            shortage = converted_required_amount - available_amount
            if shortage > 0
              # 不足量を在庫単位からレシピ単位に戻す
              shortage_in_recipe_unit = convert_from_base_unit(shortage, ingredient_unit, recipe_unit)

              if shortage_in_recipe_unit.nil?
                # 逆変換に失敗した場合は在庫単位をそのまま使用
                Rails.logger.warn({
                  event: "reverse_unit_conversion_failed",
                  ingredient_name: ingredient.name,
                  from_unit: ingredient_unit,
                  to_unit: recipe_unit,
                  message: "不足量の単位変換に失敗しました。在庫単位（#{ingredient_unit}）を使用します。"
                }.to_json)
                shortage_amount = shortage
                final_unit = if ingredient_unit.present? && ShoppingListItem::ALLOWED_UNITS.include?(ingredient_unit)
                  ingredient_unit
                else
                  "個"
                end
              else
                # 変換成功：レシピ単位を使用
                shortage_amount = shortage_in_recipe_unit
                final_unit = if recipe_unit.present? && ShoppingListItem::ALLOWED_UNITS.include?(recipe_unit)
                  recipe_unit
                else
                  "個"
                end
              end
            end
          end
        else
          # 適量の場合
          shortage_amount = required_amount
          final_unit = "適量"
        end

        if shortage_amount > 0
          missing_ingredients << {
            ingredient_id: ingredient.id,
            quantity: normalize_quantity(shortage_amount),
            unit: final_unit
          }
        end
      else
        # 新しいロジック: ingredientが存在しない場合（ingredient_id = null）
        # 在庫チェックをスキップして、レシピ量をそのまま追加
        ingredient_name = recipe_ingredient.ingredient_name
        next if ingredient_name.blank?

        # レシピ量が0以下の場合はデフォルト量（1）を使用
        final_quantity = required_amount

        # 単位の決定: レシピ単位が許可されていれば使用、なければ「個」をデフォルト
        final_unit = if !require_exact_amount
          "適量"
        elsif recipe_unit.present? && ShoppingListItem::ALLOWED_UNITS.include?(recipe_unit)
          recipe_unit
        else
          "個"
        end

        missing_ingredients << {
          ingredient_id: nil,
          ingredient_name: ingredient_name,
          quantity: normalize_quantity(final_quantity),
          unit: final_unit
        }
      end
    end

    consolidate_ingredients(missing_ingredients)
  end

  def build_user_inventory
    inventory = {}
    @inventory_name_index = Set.new

    @inventory_ingredient_ids = Set.new

    @user.user_ingredients
         .joins(:ingredient)
         .where(status: "available")
         .includes(:ingredient)
         .each do |user_ingredient|
      ingredient_id = user_ingredient.ingredient_id
      quantity = user_ingredient.quantity || 0

      @inventory_ingredient_ids << ingredient_id if ingredient_id.present?

      inventory[ingredient_id] = (inventory[ingredient_id] || 0) + quantity

      normalized_name = normalize_name(user_ingredient.ingredient&.name)
      @inventory_name_index << normalized_name if normalized_name.present?
    end

    inventory
  end

  def normalize_quantity(amount)
    return 1.0 if amount <= 0

    if amount % 1 == 0
      amount.to_i.to_f
    else
      amount.round(2)
    end
  end

  def normalize_unit(recipe_unit, ingredient_unit)
    return ingredient_unit if recipe_unit.blank?
    return recipe_unit if ShoppingListItem::ALLOWED_UNITS.include?(recipe_unit)

    ingredient_unit
  end

  # レシピ単位を食材マスター単位に変換
  def convert_to_base_unit(amount, recipe_unit, ingredient_unit)
    return amount if recipe_unit.blank? || recipe_unit == ingredient_unit

    UnitConverterService.convert(amount, from: recipe_unit, to: ingredient_unit)
  end

  # 食材マスター単位からレシピ単位に逆変換
  def convert_from_base_unit(amount, ingredient_unit, recipe_unit)
    return amount if ingredient_unit.blank? || ingredient_unit == recipe_unit

    UnitConverterService.convert(amount, from: ingredient_unit, to: recipe_unit)
  end

  # 単位変換の警告ログを出力
  def log_conversion_warning(ingredient_name, recipe_unit, ingredient_unit)
    Rails.logger.warn({
      event: "unit_conversion_failed",
      ingredient_name: ingredient_name,
      recipe_unit: recipe_unit,
      ingredient_unit: ingredient_unit,
      message: "単位変換に失敗しました。在庫差し引きをスキップしてレシピ量をそのまま使用します。"
    }.to_json)
  end

  def consolidate_ingredients(ingredients)
    consolidated = {}

    ingredients.each do |ingredient_data|
      id = ingredient_data[:ingredient_id]
      name = ingredient_data[:ingredient_name]
      quantity = ingredient_data[:quantity]

      # 集約キーの決定: ingredient_idがある場合はid、ない場合はingredient_name
      key = id || "name:#{name}"

      if consolidated[key]
        consolidated[key][:quantity] += quantity
      else
        consolidated[key] = ingredient_data.dup
      end
    end

    consolidated.values.map do |data|
      data[:quantity] = normalize_quantity(data[:quantity])
      data
    end
  end

  def ensure_required_amount(amount)
    if amount.present? && amount.to_f > 0
      amount
    else
      1.0
    end
  end

  def resolve_unit(recipe_unit, ingredient_unit)
    return recipe_unit if recipe_unit.present? && ShoppingListItem::ALLOWED_UNITS.include?(recipe_unit)
    return ingredient_unit if ingredient_unit.present? && ShoppingListItem::ALLOWED_UNITS.include?(ingredient_unit)

    "個"
  end

  def should_mark_as_checked?(ingredient_data)
    ingredient_id = ingredient_data[:ingredient_id]
    ingredient_name = ingredient_data[:ingredient_name]

    return false if ingredient_name.blank?
    return false if ingredient_id.present? # 不足量がありリストに追加されているため

    @inventory_name_index ||= Set.new
    return false if @inventory_name_index.empty?

    normalized_name = normalize_name(ingredient_name)
    return true if normalized_name.present? && @inventory_name_index.include?(normalized_name)

    matcher_result = ingredient_matcher.find_ingredient(ingredient_name)
    ingredient = matcher_result&.dig(:ingredient)
    return false unless ingredient

    return true if @inventory_ingredient_ids.include?(ingredient.id)

    matched_normalized_name = normalize_name(ingredient.name)
    matched_normalized_name.present? && @inventory_name_index.include?(matched_normalized_name)
  end

  def normalize_name(name)
    return "" if name.blank?

    ingredient_matcher.send(:normalize_ingredient_name, name)
  end

  def ingredient_matcher
    @ingredient_matcher ||= IngredientMatcher.new
  end
end
