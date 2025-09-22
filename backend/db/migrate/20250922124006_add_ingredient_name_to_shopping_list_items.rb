class AddIngredientNameToShoppingListItems < ActiveRecord::Migration[7.2]
  def change
    add_column :shopping_list_items, :ingredient_name, :string
  end
end
