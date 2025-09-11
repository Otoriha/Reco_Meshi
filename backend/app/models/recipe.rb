class Recipe < ApplicationRecord
  # Enums
  enum difficulty: {
    easy: 'easy',
    medium: 'medium',
    hard: 'hard'
  }, _prefix: :difficulty

  # Associations
  belongs_to :user
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_histories, dependent: :destroy
  has_many :shopping_lists

  # Validations
  validates :title, presence: true, length: { maximum: 100 }
  validates :cooking_time, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 480 }
  validates :steps, presence: true
  validates :ai_provider, presence: true, inclusion: { in: %w[openai gemini] }
  validates :difficulty, inclusion: { in: difficulties.keys }, allow_blank: true
  validates :servings, numericality: { greater_than: 0, less_than_or_equal_to: 20 }, allow_blank: true
  validate :validate_steps_format

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_difficulty, ->(difficulty) { where(difficulty: difficulty) }
  scope :short_cooking_time, ->(max_time = 30) { where('cooking_time <= ?', max_time) }

  # Instance methods
  def formatted_cooking_time
    hours = cooking_time / 60
    minutes = cooking_time % 60
    
    if hours > 0
      "#{hours}時間#{minutes > 0 ? "#{minutes}分" : ''}"
    else
      "#{minutes}分"
    end
  end

  def difficulty_display
    return '指定なし' if difficulty.blank?
    
    case difficulty
    when 'easy'
      '簡単 ⭐'
    when 'medium'
      '普通 ⭐⭐'
    when 'hard'
      '難しい ⭐⭐⭐'
    end
  end

  def total_ingredients_count
    recipe_ingredients.count
  end

  def optional_ingredients_count
    recipe_ingredients.where(is_optional: true).count
  end

  def required_ingredients_count
    recipe_ingredients.where(is_optional: false).count
  end

  def steps_as_array
    return [] if steps.blank?
    
    if steps.is_a?(Array) && steps.first.is_a?(Hash)
      # 構造化された形式の場合（{order: 1, text: "..."}）
      steps.sort_by { |step| step['order'] || 0 }.map { |step| step['text'] }
    elsif steps.is_a?(Array)
      # シンプルな文字列配列の場合
      steps
    else
      # その他の場合は空配列
      []
    end
  end

  private

  def validate_steps_format
    return if steps.blank?
    
    unless steps.is_a?(Array) && steps.any?
      errors.add(:steps, '調理手順は配列形式で入力してください')
    end
  end
end