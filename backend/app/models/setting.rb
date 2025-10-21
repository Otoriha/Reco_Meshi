class Setting < ApplicationRecord
  belongs_to :user

  # デフォルト値を明示的に定義
  attribute :default_servings, :integer, default: 2
  attribute :recipe_difficulty, :string, default: "medium"
  attribute :cooking_time, :integer, default: 30
  attribute :shopping_frequency, :string, default: "2-3日に1回"
  attribute :inventory_reminder_enabled, :boolean, default: false
  attribute :inventory_reminder_time, :time, default: -> { Time.zone.parse('09:00') }

  # 通知時刻はJST（日本標準時、UTC+9）で管理されています。
  # config.time_zone = 'Asia/Tokyo'により、Time.zoneは自動的にJSTとなります。
  # 将来的にユーザーごとのタイムゾーン設定が必要な場合は、
  # time_zoneカラムを追加することを検討してください。

  # バリデーション
  validates :recipe_difficulty, inclusion: { in: %w[easy medium hard] }
  validates :shopping_frequency, inclusion: { in: [ "毎日", "2-3日に1回", "週に1回", "まとめ買い" ] }
  validates :default_servings, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :cooking_time, inclusion: { in: [ 15, 30, 60, 999 ] }
  validates :inventory_reminder_enabled, inclusion: { in: [true, false] }
  validates :inventory_reminder_time, presence: true
  validate :inventory_reminder_time_is_valid

  private

  def inventory_reminder_time_is_valid
    return if inventory_reminder_time.blank?

    # time型が正しく設定されているか確認
    unless inventory_reminder_time.is_a?(Time) || inventory_reminder_time.is_a?(ActiveSupport::TimeWithZone)
      errors.add(:inventory_reminder_time, 'は有効な時刻ではありません')
    end
  end
end
