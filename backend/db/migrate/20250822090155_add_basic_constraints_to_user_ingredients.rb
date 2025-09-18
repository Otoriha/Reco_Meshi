class AddBasicConstraintsToUserIngredients < ActiveRecord::Migration[7.2]
  def change
    # 必須: statusにnull制約
    change_column_null :user_ingredients, :status, false

    # 必須: クエリ最適化
    add_index :user_ingredients, [ :user_id, :status, :expiry_date ],
              name: "idx_user_ingredients_user_status_expiry"

    # 重要: 数量の負値防止（余裕があれば）
    add_check_constraint :user_ingredients,
                        "quantity >= 0",
                        name: "chk_quantity_non_negative"
  end
end
