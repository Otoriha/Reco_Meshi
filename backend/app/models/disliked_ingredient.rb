class DislikedIngredient < ApplicationRecord
  # Enums
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2
  }, prefix: :priority

  # Associations
  belongs_to :user
  belongs_to :ingredient

  # Validations
  validates :priority, presence: true, inclusion: { in: priorities.keys }
  validates :reason, length: { maximum: 500, message: "は500文字以内で入力してください" }, allow_blank: true
  validates :ingredient_id, uniqueness: { scope: :user_id, message: "は既に登録されています" }

  # Scopes
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def priority_label
    case priority
    when "low"
      "低"
    when "medium"
      "中"
    when "high"
      "高"
    end
  end
end
