class RecipeHistory < ApplicationRecord
  # Constants
  RATING_RANGE = (1..5).freeze

  # Associations
  belongs_to :user
  belongs_to :recipe

  # Validations
  validates :cooked_at, presence: true
  validates :rating, numericality: {
    only_integer: true,
    allow_nil: true,
    in: RATING_RANGE
  }

  # Scopes
  scope :recent, -> { order(cooked_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_recipe, ->(recipe_id) { where(recipe_id: recipe_id) }
  scope :rated, -> { where.not(rating: nil) }
  scope :unrated, -> { where(rating: nil) }

  # Instance methods
  def cooked_date
    cooked_at.strftime("%Y年%m月%d日")
  end

  def cooked_time
    cooked_at.strftime("%H:%M")
  end
end
