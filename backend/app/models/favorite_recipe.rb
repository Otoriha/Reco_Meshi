class FavoriteRecipe < ApplicationRecord
  # 定数
  RATING_RANGE = 1..5

  # Associations
  belongs_to :user
  belongs_to :recipe

  # Validations
  validates :user_id, presence: true
  validates :recipe_id, presence: true
  validates :recipe_id, uniqueness: { scope: :user_id, message: "レシピIDは既にお気に入りに追加されています" }
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5, allow_nil: true }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_recipe, ->(recipe_id) { where(recipe_id: recipe_id) }
  scope :rated, -> { where.not(rating: nil) }
  scope :unrated, -> { where(rating: nil) }
end
