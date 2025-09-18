class CreateLineAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :line_accounts do |t|
      t.string :line_user_id, null: false
      t.references :user, null: true, foreign_key: { on_delete: :nullify }
      t.string :line_display_name
      t.string :line_picture_url
      t.datetime :linked_at
      t.timestamps
    end

    add_index :line_accounts, :line_user_id, unique: true
  end
end
