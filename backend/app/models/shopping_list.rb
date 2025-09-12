class ShoppingList < ApplicationRecord
  # Enums (整数型)
  enum :status, {
    pending: 0,
    in_progress: 1,
    completed: 2
  }, prefix: true
  
  # Associations
  belongs_to :user
  belongs_to :recipe, optional: true
  has_many :shopping_list_items, dependent: :destroy
  has_many :ingredients, through: :shopping_list_items
  
  # Validations
  validates :status, presence: true
  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :note, length: { maximum: 1000 }, allow_blank: true
  validate :recipe_belongs_to_user, if: -> { recipe_id.present? }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(value) do
    if value.blank?
      all
    elsif statuses.key?(value.to_s)
      where(status: statuses[value.to_s])
    else
      none
    end
  end
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :active, -> { where(status: statuses.values_at('pending', 'in_progress')) }
  scope :completed, -> { status_completed }
  
  # Instance methods
  def mark_as_completed!
    update!(status: :completed)
  end
  
  def mark_as_in_progress!
    update!(status: :in_progress)
  end
  
  def unchecked_items_count
    shopping_list_items.unchecked.count
  end
  
  def total_items_count
    shopping_list_items.count
  end
  
  def completion_percentage
    return 0 if total_items_count.zero?
    
    checked_count = shopping_list_items.checked.count
    (checked_count.to_f / total_items_count * 100).round(1)
  end
  
  def display_title
    title.presence || (recipe&.title ? "#{recipe.title}の買い物リスト" : "買い物リスト")
  end
  
  def can_be_completed?
    unchecked_items_count.zero? && total_items_count > 0
  end
  
  private
  
  def recipe_belongs_to_user
    return if recipe&.user_id == user_id
    errors.add(:recipe_id, 'は自分のレシピのみ指定可能です')
  end
end
