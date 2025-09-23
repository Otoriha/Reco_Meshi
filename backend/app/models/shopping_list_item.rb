class ShoppingListItem < ApplicationRecord
  # Constants
  ALLOWED_UNITS = %w[
    g kg ml l
    個 本 束 パック 袋 枚 缶 瓶 箱 玉 尾
    株 丁 切 杯 房 片
    大さじ 小さじ 適量
  ].freeze

  # Associations
  belongs_to :shopping_list
  belongs_to :ingredient, optional: true

  # Validations
  validates :quantity, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 9999.99 }
  validates :unit, presence: true, inclusion: {
    in: ALLOWED_UNITS,
    message: "は有効な単位を選択してください（#{ALLOWED_UNITS.join('、')}）"
  }
  validates :ingredient_id, uniqueness: {
    scope: :shopping_list_id,
    message: "は既にリストに追加されています"
  }, allow_nil: true

  validate :ingredient_or_name_present

  # Scopes
  scope :checked, -> { where(is_checked: true) }
  scope :unchecked, -> { where(is_checked: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { joins(:ingredient).where(ingredients: { category: category }) if category.present? }
  scope :ordered_by_ingredient_name, -> { joins(:ingredient).order("ingredients.name") }

  # Callbacks
  before_update :set_checked_at, if: :is_checked_changed?

  # Instance methods
  def toggle_checked!
    update!(is_checked: !is_checked)
  end

  def mark_as_checked!
    update!(is_checked: true) unless is_checked?
  end

  def mark_as_unchecked!
    update!(is_checked: false) if is_checked?
  end

  def display_quantity_with_unit
    return unit if unit == "適量"
    return unit.to_s if quantity.nil?

    display_quantity = if quantity % 1 == 0
      quantity.to_i
    else
      quantity
    end

    if unit.in?(%w[大さじ 小さじ])
      "#{display_quantity}#{unit}"
    elsif unit.blank?
      display_quantity.to_s
    else
      "#{display_quantity}#{unit}"
    end
  end

  def ingredient_display_name
    ingredient&.name || read_attribute(:ingredient_name) || "不明な材料"
  end

  def ingredient_category
    ingredient&.category || "その他"
  end

  def ingredient_emoji
    return ingredient&.emoji if ingredient

    return @resolved_ingredient_emoji if defined?(@resolved_ingredient_emoji)

    @resolved_ingredient_emoji = if ingredient_name.present?
      Ingredient.find_by(name: ingredient_name)&.emoji
    else
      nil
    end
  end

  def checked_recently?
    checked_at.present? && checked_at > 1.day.ago
  end

  private

  def set_checked_at
    self.checked_at = is_checked? ? Time.current : nil
  end

  def ingredient_or_name_present
    if ingredient_id.blank? && ingredient_name.blank?
      errors.add(:base, "食材または食材名のどちらかを指定してください")
    end
  end
end
