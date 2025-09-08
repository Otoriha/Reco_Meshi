class RecipeHistory < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :recipe

  # Validations
  validates :cooked_at, presence: true

  # Scopes
  scope :recent, -> { order(cooked_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_recipe, ->(recipe_id) { where(recipe_id: recipe_id) }

  # Instance methods
  def cooked_date
    cooked_at.strftime('%Y年%m月%d日')
  end

  def cooked_time
    cooked_at.strftime('%H:%M')
  end
end