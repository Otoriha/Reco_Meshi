class CreateFridgeImages < ActiveRecord::Migration[7.2]
  def change
    create_table :fridge_images do |t|
      # 基本的な関連
      t.references :user, null: true, foreign_key: true, index: true, comment: '撮影したユーザー'
      t.references :line_account, null: true, foreign_key: true, index: true, comment: 'LineAccountとの紐付け（Web版の場合はnull）'

      # 認識結果（メイン情報）
      t.jsonb :recognized_ingredients, null: false, default: '[]', comment: 'AI認識結果（JSON）'
      t.jsonb :image_metadata, default: '{}', comment: '画像メタデータ（JSON）'

      # 処理状態管理
      t.string :status, null: false, default: 'pending', comment: 'pending/processing/completed/failed'
      t.text :error_message, comment: 'エラー時のメッセージ'

      # LINE連携情報（トレーサビリティ用）
      t.string :line_message_id, comment: 'LINE画像メッセージID'

      # 日時管理
      t.timestamp :captured_at, comment: '撮影日時'
      t.timestamp :recognized_at, comment: '認識実行日時'

      # Rails標準
      t.timestamps
    end

    # インデックス追加
    add_index :fridge_images, [ :user_id, :created_at ], name: 'index_fridge_images_on_user_and_created'
    add_index :fridge_images, :line_message_id, where: 'line_message_id IS NOT NULL'
    add_index :fridge_images, :status
    add_index :fridge_images, :recognized_at
  end
end
