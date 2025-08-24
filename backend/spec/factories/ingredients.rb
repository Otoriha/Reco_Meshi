FactoryBot.define do
  factory :ingredient do
    sequence(:name) { |n| "#{Faker::Food.ingredient}_#{n}" }
    category { %w[vegetables meat fish dairy seasonings others].sample }
    unit { %w[個 g ml 本 枚 袋].sample }
    emoji { %w[🥕 🥔 🧅 🍅 🥬 🥒 🍗 🥩 🐟 🥛 🧂].sample }

    trait :vegetable do
      category { 'vegetables' }
      sequence(:name) { |n| "テスト野菜_#{Time.current.to_f}_#{n}" }
      unit { %w[個 本].sample }
      emoji { %w[🥕 🥔 🧅 🍅 🥬].sample }
    end

    trait :meat do
      category { 'meat' }
      sequence(:name) { |n| "テスト肉_#{Time.current.to_f}_#{n}" }
      unit { 'g' }
      emoji { %w[🍗 🥩 🥓].sample }
    end

    trait :fish do
      category { 'fish' }
      sequence(:name) { |n| "テスト魚_#{n}" }
      unit { 'g' }
      emoji { '🐟' }
    end

    trait :dairy do
      category { 'dairy' }
      sequence(:name) { |n| "テスト乳製品_#{n}" }
      unit { %w[ml g 個].sample }
      emoji { %w[🥛 🧀].sample }
    end

    trait :seasoning do
      category { 'seasonings' }
      sequence(:name) { |n| "テスト調味料_#{n}" }
      unit { %w[ml g].sample }
      emoji { %w[🧂 🍶].sample }
    end

    trait :other do
      category { 'others' }
      sequence(:name) { |n| "テストその他_#{n}" }
      unit { %w[個 g 枚].sample }
      emoji { %w[🥚 🍚 🍞 🍜].sample }
    end
  end
end