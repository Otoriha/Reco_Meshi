class CreateShoppingLists < ActiveRecord::Migration[7.2]
  def change
    create_table :shopping_lists do |t|
      t.references :user, null: false, foreign_key: true, index: true, comment: 'リスト作成者'
      t.references :recipe, foreign_key: true, index: true, comment: '基となったレシピ'
      t.integer :status, null: false, default: 0, comment: 'リストの状態（0:pending, 1:in_progress, 2:completed）'
      t.string :title, limit: 100, comment: '買い物リストタイトル'
      t.text :note, comment: 'メモ欄'

      t.timestamps
    end

    add_index :shopping_lists, :status
    add_index :shopping_lists, [ :user_id, :created_at ]
  end
end
