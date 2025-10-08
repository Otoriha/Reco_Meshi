class CreateDislikedIngredients < ActiveRecord::Migration[7.2]
  def change
    create_table :disliked_ingredients do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, comment: "ユーザーID"
      t.references :ingredient, null: false, foreign_key: { on_delete: :cascade }, comment: "食材ID"
      t.integer :priority, null: false, default: 0, comment: "優先度（0: low, 1: medium, 2: high）"
      t.text :reason, comment: "理由"

      t.timestamps
    end

    add_index :disliked_ingredients, [ :user_id, :ingredient_id ], unique: true, name: "index_disliked_ingredients_on_user_and_ingredient"
    add_check_constraint :disliked_ingredients, "priority = ANY (ARRAY[0, 1, 2])", name: "chk_priority_valid"
    add_check_constraint :disliked_ingredients, "char_length(reason) <= 500 OR reason IS NULL", name: "chk_reason_length"
  end
end
