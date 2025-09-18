class Ingredient < ApplicationRecord
  # Enums
  enum :category, {
    vegetables: "vegetables",
    meat: "meat",
    fish: "fish",
    dairy: "dairy",
    seasonings: "seasonings",
    others: "others"
  }

  # Associations
  has_many :user_ingredients, dependent: :destroy
  has_many :users, through: :user_ingredients
  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients
  has_many :shopping_list_items, dependent: :destroy
  has_many :shopping_lists, through: :shopping_list_items

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :category, presence: true
  validates :unit, presence: true, length: { maximum: 20 }
  validates :emoji, length: { maximum: 10 }

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :search, ->(query) { query.present? ? where("name ILIKE ?", "%#{query}%") : all }

  # Class methods
  def self.search_by_name(query)
    return all if query.blank?

    where("name ILIKE ?", "%#{query}%")
  end

  # Instance methods
  def display_name_with_emoji
    emoji.present? ? "#{emoji} #{name}" : name
  end
end
