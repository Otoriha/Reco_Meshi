class Setting < ApplicationRecord
  belongs_to :user

  # デフォルト値を明示的に定義
  attribute :default_servings, :integer, default: 2
  attribute :recipe_difficulty, :string, default: "medium"
  attribute :cooking_time, :integer, default: 30
  attribute :shopping_frequency, :string, default: "2-3日に1回"

  # バリデーション
  validates :recipe_difficulty, inclusion: { in: %w[easy medium hard] }
  validates :shopping_frequency, inclusion: { in: [ "毎日", "2-3日に1回", "週に1回", "まとめ買い" ] }
  validates :default_servings, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :cooking_time, inclusion: { in: [ 15, 30, 60, 999 ] }
end
