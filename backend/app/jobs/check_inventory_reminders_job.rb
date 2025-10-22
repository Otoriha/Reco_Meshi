# 在庫確認リマインダーの送信時刻をチェックするジョブ
# 毎分実行され、現在時刻に通知設定しているユーザーを抽出してリマインダーを送信
class CheckInventoryRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # 現在時刻（JST）を取得し、ログ用に保持
    current_time_jst = Time.current.in_time_zone("Asia/Tokyo")

    # time型カラムはUTCで保存されているため、UTCに変換して比較
    current_time_utc = Time.current.utc
    time_string = current_time_utc.strftime("%H:%M:00")

    # 通知対象ユーザーを取得（SQL側でフィルタリング）
    # time型カラムを文字列キャストして比較
    settings = Setting
      .joins(user: :line_account)
      .where(inventory_reminder_enabled: true)
      .where("line_accounts.linked_at IS NOT NULL")
      .where("inventory_reminder_time::text = ?", time_string)

    settings.find_each do |setting|
      SendInventoryReminderJob.perform_later(setting.user_id)
    end

    Rails.logger.info "CheckInventoryReminders: #{settings.count} users scheduled at #{current_time_jst.strftime('%H:%M')}"
  end
end
