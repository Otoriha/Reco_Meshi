class PromptTemplateService
  def self.recipe_generation(ingredients:)
    {
      system: "あなたは料理レシピ提案の専門家です。制約：日本語限定、1レシピのみ、JSON形式で出力。厳密に単一のJSONオブジェクトのみを返し、前後に説明文・補足・コードブロック等は一切含めないこと。",
      user: "食材: #{ingredients.join(', ')}\n上記食材で作れるレシピを1つ提案してください。\n出力はJSONで、例:\n{\"title\":\"...\",\"time\":\"約15分\",\"difficulty\":\"★☆☆〜★★★\",\"ingredients\":[{\"name\":\"玉ねぎ\",\"amount\":\"1個\"}],\"steps\":[\"...\"]}"
    }
  end
end
