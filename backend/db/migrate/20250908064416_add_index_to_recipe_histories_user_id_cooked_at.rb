class AddIndexToRecipeHistoriesUserIdCookedAt < ActiveRecord::Migration[7.2]
  def change
    add_index :recipe_histories, [ :user_id, :cooked_at ], name: 'index_recipe_histories_on_user_id_and_cooked_at'
  end
end
