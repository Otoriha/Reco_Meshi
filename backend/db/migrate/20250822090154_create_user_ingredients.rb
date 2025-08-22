class CreateUserIngredients < ActiveRecord::Migration[7.2]
  def change
    create_table :user_ingredients do |t|
      t.references :user, null: false, foreign_key: true, comment: 'ユーザーID'
      t.references :ingredient, null: false, foreign_key: true, comment: '食材ID'
      t.decimal :quantity, precision: 10, scale: 2, null: false, comment: '数量'
      t.date :expiry_date, comment: '賞味期限'
      t.string :status, default: 'available', comment: 'available/used/expired'
      t.references :fridge_image, foreign_key: true, comment: '認識元の画像'
      
      t.timestamps
    end
    
    add_index :user_ingredients, :status
    add_index :user_ingredients, :expiry_date
    add_index :user_ingredients, [:user_id, :ingredient_id, :status], name: 'idx_user_ingredients_composite'
  end
end
