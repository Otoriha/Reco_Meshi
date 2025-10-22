# 在庫確認リマインダーの送信時刻をチェックするジョブ
# 毎日10時と22時に実行され、その時刻に通知設定しているユーザーを抽出
class CheckInventoryRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # 現在時刻（HH:MI形式）
    current_time = Time.current.strftime("%H:%M")

    # 通知対象ユーザーを取得
    settings = Setting
      .joins(user: :line_account)
      .where(inventory_reminder_enabled: true)
      .where("line_accounts.linked_at IS NOT NULL")
      .where("to_char(inventory_reminder_time, 'HH24:MI') = ?", current_time)

    settings.each do |setting|
      SendInventoryReminderJob.perform_later(setting.user_id)
    end

    Rails.logger.info "CheckInventoryReminders: #{settings.count} users scheduled at #{current_time}"
  end
end
