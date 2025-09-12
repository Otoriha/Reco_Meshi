class ShoppingListGeneratorService
  def initialize(user, recipes = [])
    @user = user
    @recipes = Array(recipes)
    @errors = []
  end
  
  def generate
    ActiveRecord::Base.transaction do
      validate_inputs
      raise StandardError, @errors.join(', ') if @errors.any?
      
      list = create_shopping_list
      add_aggregated_items(list)
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
    @errors << 'レシピが指定されていません' if @recipes.empty?
    
    @recipes.each do |recipe|
      unless recipe.is_a?(Recipe)
        @errors << '無効なレシピが含まれています'
        next
      end
      
      unless recipe.recipe_ingredients.exists?
        @errors << "レシピ「#{recipe.title}」に材料が含まれていません"
      end
      
      unless recipe.user_id == @user.id
        @errors << "レシピ「#{recipe.title}」にアクセス権限がありません"
      end
    end
  end
  
  def create_shopping_list
    title = generate_list_title
    
    @user.shopping_lists.create!(
      status: :pending,
      title: title,
      note: generate_list_note
    )
  end
  
  def generate_list_title
    if @recipes.size == 1
      "#{@recipes.first.title}の買い物リスト"
    else
      "#{@recipes.size}レシピの買い物リスト"
    end
  end
  
  def generate_list_note
    recipe_titles = @recipes.map(&:title).join('、')
    "対象レシピ: #{recipe_titles}"
  end
  
  def add_aggregated_items(list)
    missing_ingredients = calculate_aggregated_missing_ingredients
    grouped_ingredients = group_by_category(missing_ingredients)
    
    grouped_ingredients.each_value do |category_ingredients|
      category_ingredients.each do |ingredient_data|
        list.shopping_list_items.create!(
          ingredient_id: ingredient_data[:ingredient_id],
          quantity: ingredient_data[:quantity],
          unit: ingredient_data[:unit]
        )
      end
    end
  end
  
  def calculate_aggregated_missing_ingredients
    aggregated_ingredients = {}
    user_inventory = build_user_inventory
    
    @recipes.each do |recipe|
      recipe.recipe_ingredients.includes(:ingredient).each do |recipe_ingredient|
        next if recipe_ingredient.is_optional?
        
        ingredient = recipe_ingredient.ingredient
        next unless ingredient
        
        required_amount = recipe_ingredient.amount || 0
        recipe_unit = recipe_ingredient.unit
        ingredient_unit = ingredient.unit
        
        # レシピの必要量を食材マスター単位に変換
        converted_required_amount = convert_to_base_unit(required_amount, recipe_unit, ingredient_unit)
        
        if converted_required_amount.nil?
          # 変換不可の場合は警告ログを出力し、レシピ単位でそのまま集約
          log_conversion_warning(ingredient.name, recipe_unit, ingredient_unit, recipe.title)
          unit_for_aggregation = recipe_unit
          amount_for_aggregation = required_amount
        else
          # 変換成功の場合は食材マスター単位で集約
          unit_for_aggregation = ingredient_unit
          amount_for_aggregation = converted_required_amount
        end
        
        key = "#{ingredient.id}_#{unit_for_aggregation}"
        
        if aggregated_ingredients[key]
          aggregated_ingredients[key][:total_amount] += amount_for_aggregation
        else
          aggregated_ingredients[key] = {
            ingredient: ingredient,
            total_amount: amount_for_aggregation,
            unit: unit_for_aggregation,
            converted: converted_required_amount.present?
          }
        end
      end
    end
    
    # 在庫差分を計算してリスト化
    missing_ingredients = []
    aggregated_ingredients.each_value do |agg_data|
      ingredient = agg_data[:ingredient]
      total_required = agg_data[:total_amount]
      unit = agg_data[:unit]
      converted = agg_data[:converted]
      
      if converted
        # 変換済みの場合は在庫差し引き
        available_amount = user_inventory[ingredient.id] || 0
        shortage_amount = total_required - available_amount
      else
        # 変換不可の場合は在庫考慮せず
        shortage_amount = total_required
      end
      
      if shortage_amount > 0
        missing_ingredients << {
          ingredient_id: ingredient.id,
          quantity: normalize_quantity(shortage_amount),
          unit: unit,
          ingredient: ingredient
        }
      end
    end
    
    missing_ingredients
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
  
  def group_by_category(ingredients)
    grouped = {}
    
    ingredients.each do |ingredient_data|
      category = ingredient_data[:ingredient].category || 'others'
      grouped[category] ||= []
      grouped[category] << ingredient_data
    end
    
    # カテゴリ順でソート（野菜、肉、魚、乳製品、調味料、その他）
    category_order = %w[vegetables meat fish dairy seasonings others]
    sorted_grouped = {}
    
    category_order.each do |category|
      if grouped[category]
        sorted_grouped[category] = grouped[category].sort_by { |item| item[:ingredient].name }
      end
    end
    
    # 定義されていないカテゴリがあれば最後に追加
    grouped.each do |category, items|
      unless category_order.include?(category)
        sorted_grouped[category] = items.sort_by { |item| item[:ingredient].name }
      end
    end
    
    sorted_grouped
  end
  
  def convert_to_base_unit(amount, recipe_unit, ingredient_unit)
    return amount if recipe_unit.blank? || recipe_unit == ingredient_unit
    
    UnitConverterService.convert(amount, from: recipe_unit, to: ingredient_unit)
  end
  
  def normalize_quantity(amount)
    return 1.0 if amount <= 0
    
    if amount % 1 == 0
      amount.to_i.to_f
    else
      amount.round(2)
    end
  end
  
  def log_conversion_warning(ingredient_name, recipe_unit, ingredient_unit, recipe_title)
    Rails.logger.warn({
      event: 'unit_conversion_failed_in_generator',
      ingredient_name: ingredient_name,
      recipe_unit: recipe_unit,
      ingredient_unit: ingredient_unit,
      recipe_title: recipe_title,
      message: "単位変換に失敗しました。レシピ「#{recipe_title}」の「#{ingredient_name}」について、在庫差し引きをスキップしてレシピ量をそのまま使用します。"
    }.to_json)
  end
end