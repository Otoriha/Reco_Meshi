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
    @errors << 'レシピに材料が含まれていません' if @recipe&.recipe_ingredients&.empty?
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
      available_amount = user_inventory[ingredient.id] || 0
      
      if available_amount < required_amount
        shortage_amount = required_amount - available_amount
        
        missing_ingredients << {
          ingredient_id: ingredient.id,
          quantity: normalize_quantity(shortage_amount),
          unit: normalize_unit(recipe_ingredient.unit, ingredient.unit)
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
  
  def consolidate_ingredients(ingredients)
    consolidated = {}
    
    ingredients.each do |ingredient_data|
      id = ingredient_data[:ingredient_id]
      unit = ingredient_data[:unit]
      quantity = ingredient_data[:quantity]
      
      key = "#{id}_#{unit}"
      
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
end