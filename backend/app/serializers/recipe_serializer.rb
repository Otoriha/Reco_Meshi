class RecipeSerializer
  include JSONAPI::Serializer

  attributes :id, :title, :cooking_time, :difficulty, :servings, :steps, :ai_provider, :created_at, :updated_at

  belongs_to :user
  has_many :recipe_ingredients
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_histories
  has_many :shopping_lists

  attribute :formatted_cooking_time do |object|
    object.formatted_cooking_time
  end

  attribute :difficulty_display do |object|
    object.difficulty_display
  end

  attribute :total_ingredients_count do |object|
    object.total_ingredients_count
  end

  attribute :steps_as_array do |object|
    object.steps_as_array
  end
end