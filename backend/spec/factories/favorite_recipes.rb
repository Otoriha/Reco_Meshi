FactoryBot.define do
  factory :favorite_recipe do
    association :user, :confirmed
    association :recipe
  end
end

