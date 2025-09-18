class CreateIngredients < ActiveRecord::Migration[7.2]
  def change
    create_table :ingredients do |t|
      t.string :name, null: false, comment: '食材名'
      t.string :category, null: false, comment: 'カテゴリー（野菜、肉、魚など）'
      t.string :unit, null: false, comment: '単位（個、g、mlなど）'
      t.string :emoji, comment: '絵文字アイコン'

      t.timestamps
    end

    add_index :ingredients, :name, unique: true
    add_index :ingredients, :category
  end
end
