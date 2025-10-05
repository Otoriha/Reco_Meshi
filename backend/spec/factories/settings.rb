FactoryBot.define do
  factory :setting do
    association :user
    default_servings { 2 }
    recipe_difficulty { "medium" }
    cooking_time { 30 }
    shopping_frequency { "2-3日に1回" }
  end
end
