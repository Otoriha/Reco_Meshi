FactoryBot.define do
  factory :disliked_ingredient do
    association :user
    association :ingredient
    priority { :low }
    reason { Faker::Lorem.sentence }

    trait :low do
      priority { :low }
    end

    trait :medium do
      priority { :medium }
    end

    trait :high do
      priority { :high }
    end

    trait :without_reason do
      reason { nil }
    end

    trait :with_long_reason do
      reason { "a" * 500 }
    end
  end
end
