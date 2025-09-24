FactoryBot.define do
  factory :recipe do
    association :user
    title { "テストレシピ" }
    cooking_time { 15 }
    difficulty { "easy" }
    servings { 2 }
    steps { [
      { "order" => 1, "text" => "材料を切る" },
      { "order" => 2, "text" => "炒める" }
    ] }
    ai_provider { "openai" }
    ai_response { { "source" => "spec" } }
  end
end
