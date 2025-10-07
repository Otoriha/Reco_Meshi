FactoryBot.define do
  factory :allergy_ingredient do
    association :user
    association :ingredient

    severity { :mild }
    note { Faker::Lorem.sentence }

    trait :mild do
      severity { :mild }
    end

    trait :moderate do
      severity { :moderate }
    end

    trait :severe do
      severity { :severe }
    end

    trait :without_note do
      note { nil }
    end

    trait :with_long_note do
      note { Faker::Lorem.characters(number: 500) }
    end
  end
end
