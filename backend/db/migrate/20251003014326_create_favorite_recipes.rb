class CreateFavoriteRecipes < ActiveRecord::Migration[7.2]
  def change
    create_table :favorite_recipes do |t|
      t.bigint :user_id, null: false, comment: "ユーザーID"
      t.bigint :recipe_id, null: false, comment: "レシピID"

      t.timestamps
    end

    add_index :favorite_recipes, :user_id
    add_index :favorite_recipes, :recipe_id
    add_index :favorite_recipes, [ :user_id, :created_at ], name: "index_favorite_recipes_on_user_id_and_created_at"
    add_index :favorite_recipes, [ :user_id, :recipe_id ], unique: true, name: "index_favorite_recipes_on_user_and_recipe"

    add_foreign_key :favorite_recipes, :users, on_delete: :cascade
    add_foreign_key :favorite_recipes, :recipes, on_delete: :cascade
  end
end
