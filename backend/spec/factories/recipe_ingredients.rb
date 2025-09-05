FactoryBot.define do
  factory :recipe_ingredient do
    association :recipe
    association :ingredient
    amount { 100.0 }
    unit { "g" }
    is_optional { false }

    trait :without_master do
      ingredient { nil }
      ingredient_name { "未登録食材" }
    end
  end
end


