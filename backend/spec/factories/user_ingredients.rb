FactoryBot.define do
  factory :user_ingredient do
    association :user
    association :ingredient

    quantity { Faker::Number.between(from: 0.1, to: 10.0).round(2) }
    status { 'available' }

    trait :available do
      status { 'available' }
      expiry_date { Faker::Date.between(from: 1.day.from_now, to: 2.weeks.from_now) }
    end

    trait :used do
      status { 'used' }
      expiry_date { nil }
    end

    trait :expired do
      status { 'expired' }
      expiry_date { Faker::Date.between(from: 2.weeks.ago, to: Date.current - 1.day) }
    end

    trait :expiring_soon do
      status { 'available' }
      expiry_date { Faker::Date.between(from: Date.current, to: 3.days.from_now) }
    end

    trait :with_fridge_image do
      association :fridge_image
    end

    trait :without_expiry_date do
      expiry_date { nil }
    end

    trait :large_quantity do
      quantity { Faker::Number.between(from: 10.0, to: 100.0).round(2) }
    end

    trait :small_quantity do
      quantity { Faker::Number.between(from: 0.1, to: 1.0).round(2) }
    end
  end
end
