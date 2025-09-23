class AllowNullIngredientOnShoppingListItems < ActiveRecord::Migration[7.2]
  def change
    change_column_null :shopping_list_items, :ingredient_id, true

    add_check_constraint :shopping_list_items,
                         'ingredient_id IS NOT NULL OR ingredient_name IS NOT NULL',
                         name: 'chk_shopping_list_items_ingredient_presence'
  end
end
