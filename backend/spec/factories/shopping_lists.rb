FactoryBot.define do
  factory :shopping_list do
    association :user
    status { :pending }
    title { "買い物リスト" }
    note { "メモ" }

    trait :with_recipe do
      association :recipe
      title { "#{recipe&.title || 'レシピ'}の買い物リスト" }
    end

    trait :in_progress do
      status { :in_progress }
    end

    trait :completed do
      status { :completed }
    end

    trait :with_items do
      after(:create) do |shopping_list|
        create_list(:shopping_list_item, 3, shopping_list: shopping_list)
      end
    end

    trait :with_checked_items do
      after(:create) do |shopping_list|
        create_list(:shopping_list_item, 2, :checked, shopping_list: shopping_list)
        create_list(:shopping_list_item, 1, :unchecked, shopping_list: shopping_list)
      end
    end
  end
end
