# 在庫確認リマインダーの送信時刻をチェックするジョブ
# 毎日10時と22時に実行され、その時刻に通知設定しているユーザーを抽出
class CheckInventoryRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # 現在時刻（JST）から時と分を取得
    current_time = Time.current.in_time_zone('Asia/Tokyo')
    current_hour = current_time.hour
    current_minute = current_time.min

    # 通知対象候補を取得（LINE連携済み・通知有効）
    candidate_settings = Setting
      .joins(user: :line_account)
      .where(inventory_reminder_enabled: true)
      .where("line_accounts.linked_at IS NOT NULL")

    # Rubyレベルで時刻フィルタリング（time型のタイムゾーン問題を回避）
    settings = candidate_settings.select do |setting|
      setting.inventory_reminder_time.hour == current_hour &&
        setting.inventory_reminder_time.min == current_minute
    end

    settings.each do |setting|
      SendInventoryReminderJob.perform_later(setting.user_id)
    end

    Rails.logger.info "CheckInventoryReminders: #{settings.count} users scheduled at #{current_time.strftime('%H:%M')}"
  end
end
