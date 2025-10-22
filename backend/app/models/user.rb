class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable

  # Dynamically configure devise modules based on environment variable
  devise_modules = [
    :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :jwt_authenticatable
  ]
  devise_modules << :confirmable if ENV["CONFIRMABLE_ENABLED"] == "true"

  devise(*devise_modules, jwt_revocation_strategy: JwtDenylist)

  # Associations
  has_one :line_account, dependent: :destroy
  has_one :setting, dependent: :destroy
  has_many :fridge_images, dependent: :destroy
  has_many :user_ingredients, dependent: :destroy
  has_many :ingredients, through: :user_ingredients
  has_many :recipes, dependent: :destroy
  has_many :recipe_histories, dependent: :destroy
  has_many :shopping_lists, dependent: :destroy
  has_many :favorite_recipes, dependent: :destroy
  has_many :favorited_recipes, through: :favorite_recipes, source: :recipe
  has_many :allergy_ingredients, dependent: :destroy
  has_many :allergen_ingredients, through: :allergy_ingredients, source: :ingredient
  has_many :disliked_ingredients, dependent: :destroy
  has_many :disliked_ingredient_ingredients, through: :disliked_ingredients, source: :ingredient

  # Callbacks
  after_create :build_default_setting, if: -> { setting.nil? }

  # Validations
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, if: -> { provider == "email" }
  validates :provider, inclusion: { in: %w[email line] }

  # JWT payloadの追加クレームを定義（subはdevise-jwtが自動付与）
  def jwt_payload
    is_confirmed = if ENV["CONFIRMABLE_ENABLED"] == "true"
                     confirmed_at.present?
                   else
                     true
                   end

    { "email" => email, "confirmed" => is_confirmed }
  end

  private

  def build_default_setting
    create_setting!
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create default setting for user #{id}: #{e.message}")
    true
  end
end
