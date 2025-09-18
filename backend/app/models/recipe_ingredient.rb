class RecipeIngredient < ApplicationRecord
  # Associations
  belongs_to :recipe
  belongs_to :ingredient, optional: true

  # Validations
  validates :amount, numericality: { greater_than: 0 }, allow_blank: true
  validates :unit, length: { maximum: 20 }, allow_blank: true
  validate :ingredient_id_or_name_present

  # Scopes
  scope :required, -> { where(is_optional: false) }
  scope :optional, -> { where(is_optional: true) }
  scope :with_matched_ingredient, -> { where.not(ingredient_id: nil) }
  scope :with_unmatched_ingredient, -> { where(ingredient_id: nil) }

  # Instance methods
  def display_name
    if ingredient.present?
      ingredient.display_name_with_emoji
    else
      ingredient_name || "不明な食材"
    end
  end

  def formatted_amount
    return "" if amount.blank? && unit.blank?

    amount_text = amount.present? ? amount.to_s.sub(/\.0$/, "") : ""
    unit_text = unit.present? ? unit : ""

    "#{amount_text}#{unit_text}"
  end

  def full_display
    name = display_name
    amount_unit = formatted_amount

    if amount_unit.present?
      "#{name} #{amount_unit}"
    else
      name
    end
  end

  def matched?
    ingredient_id.present?
  end

  def unmatched?
    !matched?
  end

  def optional_display
    is_optional? ? "（お好みで）" : ""
  end

  def category
    return ingredient.category if ingredient.present?
    "unknown"
  end

  def category_display
    return ingredient.category.humanize if ingredient.present?
    "不明"
  end

  # Class methods
  def self.group_by_category
    includes(:ingredient)
      .group_by(&:category)
      .transform_keys(&:humanize)
  end

  def self.required_count
    required.count
  end

  def self.optional_count
    optional.count
  end

  def self.matched_count
    with_matched_ingredient.count
  end

  def self.unmatched_count
    with_unmatched_ingredient.count
  end

  private

  def ingredient_id_or_name_present
    if ingredient_id.blank? && ingredient_name.blank?
      errors.add(:base, "食材IDまたは食材名のいずれかを入力してください")
    end
  end
end
