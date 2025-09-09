class AddRatingToRecipeHistories < ActiveRecord::Migration[7.2]
  def change
    add_column :recipe_histories, :rating, :integer, null: true
    add_check_constraint :recipe_histories, 'rating BETWEEN 1 AND 5', name: 'rating_between_1_and_5'
  end
end
