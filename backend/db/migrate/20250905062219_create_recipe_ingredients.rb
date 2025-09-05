class CreateRecipeIngredients < ActiveRecord::Migration[7.2]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }, comment: 'レシピID'
      t.references :ingredient, null: true, foreign_key: true, comment: '食材ID（マッチング成功時）'
      t.string :ingredient_name, comment: '食材名（マッチング失敗時のフォールバック）'
      t.decimal :amount, precision: 10, scale: 2, comment: '必要量'
      t.string :unit, limit: 20, comment: '単位（g、個、大さじ等）'
      t.boolean :is_optional, null: false, default: false, comment: '任意の食材フラグ'

      t.timestamps
    end

    
    add_check_constraint :recipe_ingredients, 'ingredient_id IS NOT NULL OR ingredient_name IS NOT NULL', name: 'chk_ingredient_id_or_name_required'
  end
end
