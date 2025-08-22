FactoryBot.define do
  factory :ingredient do
    name { Faker::Food.ingredient }
    category { %w[vegetables meat fish dairy seasonings others].sample }
    unit { %w[個 g ml 本 枚 袋].sample }
    emoji { %w[🥕 🥔 🧅 🍅 🥬 🥒 🍗 🥩 🐟 🥛 🧂].sample }

    trait :vegetable do
      category { 'vegetables' }
      name { %w[にんじん じゃがいも 玉ねぎ トマト キャベツ].sample }
      unit { %w[個 本].sample }
      emoji { %w[🥕 🥔 🧅 🍅 🥬].sample }
    end

    trait :meat do
      category { 'meat' }
      name { %w[鶏肉 豚肉 牛肉 ひき肉].sample }
      unit { 'g' }
      emoji { %w[🍗 🥩 🥓].sample }
    end

    trait :fish do
      category { 'fish' }
      name { %w[鮭 まぐろ さば いわし].sample }
      unit { 'g' }
      emoji { '🐟' }
    end

    trait :dairy do
      category { 'dairy' }
      name { %w[牛乳 チーズ ヨーグルト バター].sample }
      unit { %w[ml g 個].sample }
      emoji { %w[🥛 🧀].sample }
    end

    trait :seasoning do
      category { 'seasonings' }
      name { %w[醤油 みりん 塩 砂糖 味噌].sample }
      unit { %w[ml g].sample }
      emoji { %w[🧂 🍶].sample }
    end

    trait :other do
      category { 'others' }
      name { %w[卵 米 パン 麺].sample }
      unit { %w[個 g 枚].sample }
      emoji { %w[🥚 🍚 🍞 🍜].sample }
    end
  end
end