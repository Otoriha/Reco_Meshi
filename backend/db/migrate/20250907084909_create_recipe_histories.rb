class CreateRecipeHistories < ActiveRecord::Migration[7.2]
  def change
    create_table :recipe_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.datetime :cooked_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.text :memo

      t.timestamps
    end
  end
end
