FactoryBot.define do
  factory :favorite_recipe do
    association :user, :confirmed
    recipe { association :recipe, user: user }
  end
end
