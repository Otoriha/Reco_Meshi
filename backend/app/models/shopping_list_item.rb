class ShoppingListItem < ApplicationRecord
  # Constants
  ALLOWED_UNITS = %w[g kg ml l 個 本 束 パック 袋 枚 缶 瓶 箱 玉 尾].freeze

  # Associations
  belongs_to :shopping_list
  belongs_to :ingredient

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
  }

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
    if quantity % 1 == 0
      "#{quantity.to_i}#{unit}"
    else
      "#{quantity}#{unit}"
    end
  end

  def ingredient_name
    ingredient.name
  end

  def ingredient_category
    ingredient.category
  end

  def checked_recently?
    checked_at.present? && checked_at > 1.day.ago
  end

  private

  def set_checked_at
    self.checked_at = is_checked? ? Time.current : nil
  end
end
