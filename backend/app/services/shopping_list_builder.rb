class ShoppingListBuilder
  def initialize(user, recipe)
    @user = user
    @recipe = recipe
    @errors = []
  end
  
  def build
    ActiveRecord::Base.transaction do
      validate_inputs
      raise StandardError, @errors.join(', ') if @errors.any?
      
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
    @errors << 'ユーザーが指定されていません' unless @user
    @errors << 'レシピが指定されていません' unless @recipe
    if @recipe && !@recipe.recipe_ingredients.exists?
      @errors << 'レシピに材料が含まれていません'
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
      list.shopping_list_items.create!(
        ingredient_id: ingredient_data[:ingredient_id],
        quantity: ingredient_data[:quantity],
        unit: ingredient_data[:unit]
      )
    end
  end
  
  def calculate_missing_ingredients
    missing_ingredients = []
    user_inventory = build_user_inventory
    
    @recipe.recipe_ingredients.includes(:ingredient).each do |recipe_ingredient|
      next if recipe_ingredient.is_optional?
      
      ingredient = recipe_ingredient.ingredient
      next unless ingredient
      
      required_amount = recipe_ingredient.amount || 0
      recipe_unit = recipe_ingredient.unit
      ingredient_unit = ingredient.unit
      
      # レシピの必要量を食材マスター単位に変換
      converted_required_amount = convert_to_base_unit(required_amount, recipe_unit, ingredient_unit)
      available_amount = user_inventory[ingredient.id] || 0
      
      # 変換結果に基づいて不足量を計算
      shortage_amount = if converted_required_amount.nil?
        # 変換不可の場合は在庫を考慮せずレシピ量をそのまま使用
        log_conversion_warning(ingredient.name, recipe_unit, ingredient_unit)
        required_amount
      else
        # 変換成功の場合は在庫差し引き
        shortage = converted_required_amount - available_amount
        shortage > 0 ? shortage : 0
      end
      
      if shortage_amount > 0
        # 最終単位の決定ロジック
        final_unit = if converted_required_amount.nil?
          # 変換失敗時: レシピ単位が許可されていれば使用、未許可なら食材単位にフォールバック
          ShoppingListItem::ALLOWED_UNITS.include?(recipe_unit) ? recipe_unit : ingredient_unit
        else
          # 変換成功時: 食材マスター単位に統一
          ingredient_unit
        end
        
        missing_ingredients << {
          ingredient_id: ingredient.id,
          quantity: normalize_quantity(shortage_amount),
          unit: final_unit
        }
      end
    end
    
    consolidate_ingredients(missing_ingredients)
  end
  
  def build_user_inventory
    inventory = {}
    
    @user.user_ingredients
         .joins(:ingredient)
         .where(status: 'available')
         .includes(:ingredient)
         .each do |user_ingredient|
      ingredient_id = user_ingredient.ingredient_id
      quantity = user_ingredient.quantity || 0
      
      inventory[ingredient_id] = (inventory[ingredient_id] || 0) + quantity
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
  
  # 単位変換の警告ログを出力
  def log_conversion_warning(ingredient_name, recipe_unit, ingredient_unit)
    Rails.logger.warn({
      event: 'unit_conversion_failed',
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
      quantity = ingredient_data[:quantity]
      
      # 単位変換後は ingredient_id のみで集約（単位が統一されているため）
      if consolidated[id]
        consolidated[id][:quantity] += quantity
      else
        consolidated[id] = ingredient_data.dup
      end
    end
    
    consolidated.values.map do |data|
      data[:quantity] = normalize_quantity(data[:quantity])
      data
    end
  end
end