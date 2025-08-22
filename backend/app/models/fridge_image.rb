class FridgeImage < ApplicationRecord
  # アソシエーション
  belongs_to :user, optional: true
  belongs_to :line_account, optional: true

  # Enum定義
  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  # バリデーション
  validates :status, presence: true

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :with_ingredients, -> { where(status: 'completed').where.not(recognized_ingredients: []) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_line_account, ->(line_account) { where(line_account: line_account) }

  # 認識結果に関するメソッド
  def has_ingredients?
    completed? && recognized_ingredients.present? && recognized_ingredients.is_a?(Array) && recognized_ingredients.any?
  end

  def ingredient_count
    return 0 unless has_ingredients?
    recognized_ingredients.size
  end

  def top_ingredients(limit = 5)
    return [] unless has_ingredients?
    recognized_ingredients.first(limit)
  end

  def ingredient_names
    return [] unless has_ingredients?
    recognized_ingredients.map { |ingredient| ingredient['name'] }.compact
  end

  # ステータス管理メソッド
  def start_processing!
    update!(status: 'processing', recognized_at: nil, error_message: nil)
  end

  def complete_with_result!(ingredients_data, metadata = {})
    update!(
      status: 'completed',
      recognized_ingredients: ingredients_data,
      image_metadata: metadata,
      recognized_at: Time.current,
      error_message: nil
    )
  end

  def fail_with_error!(error_message)
    update!(
      status: 'failed',
      # 確実に配列型で保持するため明示的に空配列を保存
      recognized_ingredients: [],
      error_message: error_message,
      recognized_at: Time.current
    )
  end

  # LINE関連のヘルパーメソッド
  def from_line?
    line_message_id.present? && line_account.present?
  end

  def from_web?
    line_message_id.blank? && user.present?
  end

  private
end