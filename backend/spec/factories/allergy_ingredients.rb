FactoryBot.define do
  factory :allergy_ingredient do
    association :user
    association :ingredient

    note { Faker::Lorem.sentence }

    trait :without_note do
      note { nil }
    end

    trait :with_long_note do
      note { Faker::Lorem.characters(number: 500) }
    end
  end
end
