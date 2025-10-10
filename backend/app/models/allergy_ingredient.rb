class AllergyIngredient < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :ingredient

  # Validations
  validates :note, length: { maximum: 500, message: "は500文字以内で入力してください" }, allow_blank: true
  validates :ingredient_id, uniqueness: { scope: :user_id, message: "は既に登録されています" }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
end
