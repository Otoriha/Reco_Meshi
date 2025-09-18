FactoryBot.define do
  factory :shopping_list_item do
    association :shopping_list
    association :ingredient
    quantity { 1.0 }
    unit { "個" }
    is_checked { false }

    trait :checked do
      is_checked { true }
      checked_at { Time.current }
    end

    trait :unchecked do
      is_checked { false }
      checked_at { nil }
    end

    trait :with_decimal_quantity do
      quantity { 2.5 }
      unit { "g" }
    end

    trait :large_quantity do
      quantity { 1000.0 }
      unit { "g" }
    end

    factory :shopping_list_item_vegetables do
      after(:build) do |item|
        ingredient = create(:ingredient, category: 'vegetables', name: '玉ねぎ', unit: '個')
        item.ingredient = ingredient
      end
    end

    factory :shopping_list_item_meat do
      after(:build) do |item|
        ingredient = create(:ingredient, category: 'meat', name: '豚肉', unit: 'g')
        item.ingredient = ingredient
        item.unit = 'g'
        item.quantity = 300.0
      end
    end
  end
end
