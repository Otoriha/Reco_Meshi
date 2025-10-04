class CreateSettings < ActiveRecord::Migration[7.2]
  def up
    create_table :settings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }, comment: "ユーザーID"
      t.integer :default_servings, default: 2, null: false, comment: "デフォルトの人数"
      t.string :recipe_difficulty, default: "medium", comment: "レシピの難易度（easy/medium/hard）"
      t.integer :cooking_time, default: 30, null: false, comment: "調理時間の目安（分）"
      t.string :shopping_frequency, default: "2-3日に1回", comment: "買い物の頻度"

      t.timestamps
    end

    # 既存ユーザー全員分のデフォルトレコード作成（生SQL）
    execute <<-SQL
      INSERT INTO settings (user_id, default_servings, recipe_difficulty, cooking_time, shopping_frequency, created_at, updated_at)
      SELECT id, 2, 'medium', 30, '2-3日に1回', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users
      WHERE NOT EXISTS (SELECT 1 FROM settings WHERE settings.user_id = users.id)
    SQL
  end

  def down
    drop_table :settings
  end
end
