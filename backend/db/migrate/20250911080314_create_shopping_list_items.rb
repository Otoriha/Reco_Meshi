class CreateShoppingListItems < ActiveRecord::Migration[7.2]
  def change
    create_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true, index: true, comment: '所属する買い物リスト'
      t.references :ingredient, null: false, foreign_key: true, index: true, comment: '購入する食材'
      t.decimal :quantity, null: false, precision: 10, scale: 2, comment: '購入量'
      t.string :unit, null: false, limit: 20, comment: '単位'
      t.boolean :is_checked, null: false, default: false, comment: '購入済みチェック'
      t.datetime :checked_at, comment: 'チェック日時（監査用）'
      t.integer :lock_version, null: false, default: 0, comment: '楽観ロック用バージョン'

      t.timestamps
    end

    add_index :shopping_list_items, [ :shopping_list_id, :ingredient_id ], unique: true
    add_index :shopping_list_items, :is_checked
  end
end
