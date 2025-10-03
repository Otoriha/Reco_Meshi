class FavoriteRecipe < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :recipe

  # Validations
  validates :user_id, presence: true
  validates :recipe_id, presence: true
  validates :recipe_id, uniqueness: { scope: :user_id, message: "レシピIDは既にお気に入りに追加されています" }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_recipe, ->(recipe_id) { where(recipe_id: recipe_id) }
end
