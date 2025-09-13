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
    # 1. まず食材毎にレシピ要求量を集約
    ingredient_requirements = {}
    
    @recipes.each do |recipe|
      recipe.recipe_ingredients.includes(:ingredient).each do |recipe_ingredient|
        next if recipe_ingredient.is_optional?
        
        ingredient = recipe_ingredient.ingredient
        next unless ingredient
        
        required_amount = recipe_ingredient.amount || 0
        recipe_unit = recipe_ingredient.unit
        
        ingredient_requirements[ingredient.id] ||= { 
          ingredient: ingredient, 
          requirements: [] 
        }
        
        ingredient_requirements[ingredient.id][:requirements] << {
          amount: required_amount,
          unit: recipe_unit,
          recipe_title: recipe.title
        }
      end
    end
    
    # 2. 各食材について単位統一と集約を実行
    user_inventory = build_user_inventory
    missing_ingredients = []
    
    ingredient_requirements.each_value do |req_data|
      ingredient = req_data[:ingredient]
      requirements = req_data[:requirements]
      ingredient_unit = ingredient.unit
      
      # 食材マスター単位での総必要量を計算
      total_required_in_base_unit = 0
      unconvertible_amounts = []
      
      requirements.each do |req|
        converted_amount = convert_to_base_unit(req[:amount], req[:unit], ingredient_unit)
        
        if converted_amount.nil?
          # 変換不可の場合はWARNログと共に記録
          log_conversion_warning(ingredient.name, req[:unit], ingredient_unit, req[:recipe_title])
          unconvertible_amounts << req
        else
          # 変換成功の場合は食材マスター単位で合算
          total_required_in_base_unit += converted_amount
        end
      end
      
      # 変換不可分の処理：可能であれば食材マスター単位に変換を試行
      unconvertible_amounts.each do |req|
        # レシピ単位→食材マスター単位の逆変換を試行（例: cup→mlなど、将来の拡張で対応可能）
        fallback_converted = attempt_fallback_conversion(req[:amount], req[:unit], ingredient_unit)
        
        if fallback_converted
          total_required_in_base_unit += fallback_converted
        else
          # 完全に変換不可の場合は警告を出して、概算値として1単位を加算
          log_unconvertible_warning(ingredient.name, req[:unit], ingredient_unit, req[:recipe_title], req[:amount])
          
          # 変換不可分は概算で1単位として計上（安全のため）
          total_required_in_base_unit += req[:amount]
        end
      end
      
      # 在庫差分を計算
      available_amount = user_inventory[ingredient.id] || 0
      shortage_amount = total_required_in_base_unit - available_amount
      
      if shortage_amount > 0
        missing_ingredients << {
          ingredient_id: ingredient.id,
          quantity: normalize_quantity(shortage_amount),
          unit: ingredient_unit, # 最終単位は必ず食材マスター単位
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
  
  def attempt_fallback_conversion(amount, recipe_unit, ingredient_unit)
    # 将来的に拡張可能な変換ルール（例：カップ→ml、小さじ→ml等）
    # 現在は基本的にUnitConverterServiceで処理しきれないもの
    # とりあえずnilを返して標準変換に委ねる
    nil
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
  
  def log_unconvertible_warning(ingredient_name, recipe_unit, ingredient_unit, recipe_title, amount)
    Rails.logger.warn({
      event: 'unit_completely_unconvertible_in_generator',
      ingredient_name: ingredient_name,
      recipe_unit: recipe_unit,
      ingredient_unit: ingredient_unit,
      recipe_title: recipe_title,
      amount: amount,
      message: "単位変換が完全に不可能です。レシピ「#{recipe_title}」の「#{ingredient_name}」#{amount}#{recipe_unit}を概算値として処理します。"
    }.to_json)
  end
end