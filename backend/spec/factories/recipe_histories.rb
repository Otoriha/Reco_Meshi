FactoryBot.define do
  factory :recipe_history do
    association :user
    association :recipe
    cooked_at { Time.current }
    memo { '美味しかった' }
  end
end

