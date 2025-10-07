class AllergyIngredient < ApplicationRecord
  # Enums
  enum :severity, {
    mild: 0,
    moderate: 1,
    severe: 2
  }, prefix: :severity

  # Associations
  belongs_to :user
  belongs_to :ingredient

  # Validations
  validates :severity, presence: true, inclusion: { in: severities.keys }
  validates :note, length: { maximum: 500 }, allow_blank: true
  validates :ingredient_id, uniqueness: { scope: :user_id, message: "は既に登録されています" }

  # Scopes
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def severity_label
    case severity
    when "mild"
      "軽度"
    when "moderate"
      "中程度"
    when "severe"
      "重度"
    end
  end
end
