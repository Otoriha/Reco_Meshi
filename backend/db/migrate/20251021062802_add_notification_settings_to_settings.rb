class AddNotificationSettingsToSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :settings, :inventory_reminder_enabled, :boolean,
      default: false, null: false,
      comment: '在庫確認リマインダーの有効/無効'

    add_column :settings, :inventory_reminder_time, :time,
      default: '09:00:00', null: false,
      comment: '通知送信時刻（JST、HH:MM:SS形式）'
  end
end
