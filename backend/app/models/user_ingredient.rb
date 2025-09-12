class UserIngredient < ApplicationRecord
  # Enums
  enum :status, {
    available: 'available',
    used: 'used',
    expired: 'expired'
  }

  # Associations
  belongs_to :user
  belongs_to :ingredient
  belongs_to :fridge_image, optional: true

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: statuses.keys }
  validates :expiry_date, presence: false
  validate :expiry_date_not_in_past, if: -> { expiry_date.present? && available? }

  # Scopes
  scope :available, -> { where(status: 'available') }
  scope :expired, -> { where(status: 'expired') }
  scope :expiring_soon, ->(days = 7) { 
    available.where.not(expiry_date: nil)
             .where(expiry_date: ..(Date.current + days.days))
  }
  scope :by_category, ->(category) { joins(:ingredient).where(ingredients: { category: category }) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def expired?
    return false if expiry_date.blank?
    
    expiry_date < Date.current
  end

  def expiring_soon?(days = 7)
    return false if expiry_date.blank?
    
    expiry_date <= Date.current + days.days
  end

  def days_until_expiry
    return nil if expiry_date.blank?
    
    (expiry_date - Date.current).to_i
  end

  def display_name
    ingredient.display_name_with_emoji
  end

  def formatted_quantity
    "#{quantity}#{ingredient.unit}"
  end

  # Class methods
  def self.group_by_category
    includes(:ingredient)
      .group_by { |ui| ui.ingredient.category }
      .transform_keys { |k| I18n.t("ingredients.categories.#{k}", default: k.humanize) }
  end

  private

  def expiry_date_not_in_past
    return unless expiry_date.present? && expiry_date < Date.current
    
    errors.add(:expiry_date, '過去の日付は設定できません')
  end
end
