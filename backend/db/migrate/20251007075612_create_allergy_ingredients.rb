class CreateAllergyIngredients < ActiveRecord::Migration[7.2]
  def change
    create_table :allergy_ingredients do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, comment: "ユーザーID"
      t.references :ingredient, null: false, foreign_key: { on_delete: :cascade }, comment: "食材ID"
      t.integer :severity, null: false, default: 0, comment: "重症度（0: mild, 1: moderate, 2: severe）"
      t.text :note, comment: "備考"

      t.timestamps
    end

    add_index :allergy_ingredients, [ :user_id, :ingredient_id ], unique: true, name: "index_allergy_ingredients_on_user_and_ingredient"
    add_check_constraint :allergy_ingredients, "severity IN (0, 1, 2)", name: "chk_severity_valid"
    add_check_constraint :allergy_ingredients, "LENGTH(note) <= 500 OR note IS NULL", name: "chk_note_length"
  end
end
