# 個別ユーザーにLINE在庫確認リマインダーを送信するジョブ
class SendInventoryReminderJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  def perform(user_id)
    user = User.includes(:line_account).find(user_id)
    return unless user.line_account&.linked?

    stats = InventoryStatsService.new(user)
    bot = LineBotService.new
    message = build_reminder_message(stats, bot)

    bot.push_message(user.line_account.line_user_id, message)

    Rails.logger.info "Inventory reminder sent to user #{user_id}"
  rescue => e
    Rails.logger.error "Failed to send reminder to user #{user_id}: #{e.message}"
    raise
  end

  private

  def build_reminder_message(stats, bot)
    bot.create_flex_message(
      "今日の在庫確認",
      create_inventory_reminder_bubble(stats, bot)
    )
  end

  def create_inventory_reminder_bubble(stats, bot)
    {
      type: "bubble",
      body: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: "📦 今日の在庫確認",
            weight: "bold",
            size: "xl",
            color: "#42A5F5"
          },
          {
            type: "text",
            text: "現在の在庫: #{stats.total_count}品",
            margin: "md",
            size: "md"
          },
          *expiring_soon_section(stats)
        ]
      },
      footer: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "button",
            action: {
              type: "uri",
              label: "在庫を確認する",
              uri: bot.generate_liff_url("/ingredients")
            },
            style: "primary",
            color: "#42A5F5"
          },
          {
            type: "button",
            action: {
              type: "uri",
              label: "レシピを見る",
              uri: bot.generate_liff_url("/recipes")
            },
            style: "link"
          }
        ]
      }
    }
  end

  def expiring_soon_section(stats)
    expiring = stats.expiring_soon_ingredients
    return [] if expiring.empty?

    [
      {
        type: "separator",
        margin: "md"
      },
      {
        type: "text",
        text: "⚠️ 期限切れ間近（3日以内）",
        weight: "bold",
        color: "#FF5722",
        margin: "md"
      },
      *expiring.map { |ui|
        {
          type: "text",
          text: "• #{ui.ingredient.name}",
          size: "sm",
          color: "#666666"
        }
      }
    ]
  end
end
