class RemoveSeverityFromAllergyIngredients < ActiveRecord::Migration[7.2]
  def up
    # CHECK制約を削除（存在しない場合でもエラーにならないようにif_exists: trueを使用）
    remove_check_constraint :allergy_ingredients, name: "chk_severity_valid", if_exists: true

    # severityカラムを削除
    remove_column :allergy_ingredients, :severity
  end

  def down
    # severityカラムを追加（ロールバック対応）
    add_column :allergy_ingredients, :severity, :integer, null: false, default: 0, comment: "重症度（0: mild, 1: moderate, 2: severe）"

    # CHECK制約を再追加
    add_check_constraint :allergy_ingredients, "severity IN (0, 1, 2)", name: "chk_severity_valid"
  end
end
