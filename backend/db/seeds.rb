# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 基本的な食材マスタデータを作成
ingredients_data = [
  # 野菜類
  { name: 'にんじん', category: 'vegetables', unit: '本', emoji: '🥕' },
  { name: 'じゃがいも', category: 'vegetables', unit: '個', emoji: '🥔' },
  { name: '玉ねぎ', category: 'vegetables', unit: '個', emoji: '🧅' },
  { name: 'トマト', category: 'vegetables', unit: '個', emoji: '🍅' },
  { name: 'キャベツ', category: 'vegetables', unit: '個', emoji: '🥬' },
  { name: 'きゅうり', category: 'vegetables', unit: '本', emoji: '🥒' },
  { name: 'なす', category: 'vegetables', unit: '本', emoji: '🍆' },
  { name: 'ピーマン', category: 'vegetables', unit: '個', emoji: '🫑' },
  { name: 'ブロッコリー', category: 'vegetables', unit: '個', emoji: '🥦' },
  { name: 'レタス', category: 'vegetables', unit: '個', emoji: '🥬' },
  { name: 'ほうれん草', category: 'vegetables', unit: '束', emoji: '🥬' },
  { name: '白菜', category: 'vegetables', unit: '個', emoji: '🥬' },
  { name: 'もやし', category: 'vegetables', unit: '袋', emoji: '🌱' },
  { name: '大根', category: 'vegetables', unit: '本', emoji: '🟠' },

  # 肉類
  { name: '鶏胸肉', category: 'meat', unit: 'g', emoji: '🍗' },
  { name: '鶏もも肉', category: 'meat', unit: 'g', emoji: '🍗' },
  { name: '豚こま切れ肉', category: 'meat', unit: 'g', emoji: '🥩' },
  { name: '豚バラ肉', category: 'meat', unit: 'g', emoji: '🥓' },
  { name: '牛こま切れ肉', category: 'meat', unit: 'g', emoji: '🥩' },
  { name: '牛ステーキ肉', category: 'meat', unit: 'g', emoji: '🥩' },
  { name: '鶏ひき肉', category: 'meat', unit: 'g', emoji: '🍗' },
  { name: '豚ひき肉', category: 'meat', unit: 'g', emoji: '🐷' },
  { name: '牛ひき肉', category: 'meat', unit: 'g', emoji: '🐄' },

  # 魚類
  { name: '鮭', category: 'fish', unit: '切', emoji: '🐟' },
  { name: 'まぐろ', category: 'fish', unit: 'g', emoji: '🐟' },
  { name: 'さば', category: 'fish', unit: '尾', emoji: '🐟' },
  { name: 'いわし', category: 'fish', unit: '尾', emoji: '🐟' },
  { name: 'ぶり', category: 'fish', unit: '切', emoji: '🐟' },
  { name: 'あじ', category: 'fish', unit: '尾', emoji: '🐟' },

  # 乳製品類
  { name: '牛乳', category: 'dairy', unit: 'ml', emoji: '🥛' },
  { name: 'チーズ', category: 'dairy', unit: 'g', emoji: '🧀' },
  { name: 'ヨーグルト', category: 'dairy', unit: 'g', emoji: '🥛' },
  { name: 'バター', category: 'dairy', unit: 'g', emoji: '🧈' },
  { name: '生クリーム', category: 'dairy', unit: 'ml', emoji: '🥛' },

  # 調味料類
  { name: '醤油', category: 'seasonings', unit: 'ml', emoji: '🍶' },
  { name: 'みりん', category: 'seasonings', unit: 'ml', emoji: '🍶' },
  { name: '料理酒', category: 'seasonings', unit: 'ml', emoji: '🍶' },
  { name: '塩', category: 'seasonings', unit: 'g', emoji: '🧂' },
  { name: '砂糖', category: 'seasonings', unit: 'g', emoji: '🧂' },
  { name: '味噌', category: 'seasonings', unit: 'g', emoji: '🍜' },
  { name: 'サラダ油', category: 'seasonings', unit: 'ml', emoji: '🫗' },
  { name: 'ごま油', category: 'seasonings', unit: 'ml', emoji: '🫗' },
  { name: '酢', category: 'seasonings', unit: 'ml', emoji: '🍶' },
  { name: 'マヨネーズ', category: 'seasonings', unit: 'g', emoji: '🥫' },

  # その他
  { name: '卵', category: 'others', unit: '個', emoji: '🥚' },
  { name: '米', category: 'others', unit: 'g', emoji: '🍚' },
  { name: '食パン', category: 'others', unit: '枚', emoji: '🍞' },
  { name: 'うどん', category: 'others', unit: '玉', emoji: '🍜' },
  { name: 'そば', category: 'others', unit: '束', emoji: '🍜' },
  { name: 'パスタ', category: 'others', unit: 'g', emoji: '🍝' },
  { name: '豆腐', category: 'others', unit: '丁', emoji: '🥚' },
  { name: '納豆', category: 'others', unit: 'パック', emoji: '🫘' }
]

puts '食材マスタデータを作成中...'

ingredients_data.each do |ingredient_data|
  ingredient = Ingredient.find_or_create_by!(name: ingredient_data[:name]) do |i|
    i.category = ingredient_data[:category]
    i.unit = ingredient_data[:unit]
    i.emoji = ingredient_data[:emoji]
  end
  
  puts "✓ #{ingredient.display_name_with_emoji} (#{ingredient.category})"
end

puts "食材マスタデータの作成完了！ 合計: #{Ingredient.count}件"
