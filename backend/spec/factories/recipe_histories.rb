FactoryBot.define do
  factory :recipe_history do
    association :user
    association :recipe
    cooked_at { Time.current }
    memo { '美味しかった' }
    rating { nil }

    trait :rated do
      rating { 3 }
    end

    trait :unrated do
      rating { nil }
    end

    trait :highly_rated do
      rating { 5 }
    end

    trait :poorly_rated do
      rating { 1 }
    end
  end
end
