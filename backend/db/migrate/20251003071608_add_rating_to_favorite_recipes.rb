class AddRatingToFavoriteRecipes < ActiveRecord::Migration[7.2]
  def change
    add_column :favorite_recipes, :rating, :integer, comment: "評価（1-5）"
  end
end
