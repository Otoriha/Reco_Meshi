class MessageResponseService
  def initialize(line_bot_service)
    @line_bot_service = line_bot_service
  end

  def generate_response(command, user_id = nil)
    case command
    when :greeting
      create_greeting_message
    when :recipe
      create_recipe_suggestion_message
    when :ingredients
      create_ingredients_list_message
    when :shopping
      create_shopping_list_message
    when :help
      create_help_message
    when :unknown
      create_unknown_message
    else
      create_unknown_message
    end
  end

  private

  def create_greeting_message
    @line_bot_service.create_text_message(
      "こんにちは！レコめしへようこそ🍽️\n\n" \
      "冷蔵庫の写真を送ってくれれば、今ある食材で作れるレシピを提案します！\n\n" \
      "📝 使えるコマンド:\n" \
      "• 「レシピ」- レシピ提案\n" \
      "• 「食材」- 食材リスト表示\n" \
      "• 「買い物」- 買い物リスト表示\n" \
      "• 「ヘルプ」- 使い方説明"
    )
  end

  def create_recipe_suggestion_message
    # 将来的にはユーザーの食材データベースから取得してAIでレシピ生成
    mock_ingredients = [ "玉ねぎ", "人参", "じゃがいも", "豚肉" ]

    @line_bot_service.create_text_message(
      "🍳 今ある食材でのレシピ提案\n\n" \
      "現在の食材: #{mock_ingredients.join(', ')}\n\n" \
      "📖 おすすめレシピ:\n" \
      "「豚肉と野菜の炒め物」\n" \
      "・調理時間: 約15分\n" \
      "・難易度: ★★☆\n\n" \
      "詳しい作り方はLIFFアプリでご確認ください！\n\n" \
      "※現在はサンプルデータを表示しています。正式版では実際の食材データに基づいてAIがレシピを提案します。"
    )
  end

  def create_ingredients_list_message
    # 将来的にはユーザーの実際の食材リストを表示
    mock_ingredients = [
      { name: "玉ねぎ", quantity: "2個", expiry: "3日後" },
      { name: "人参", quantity: "1本", expiry: "5日後" },
      { name: "じゃがいも", quantity: "3個", expiry: "1週間後" },
      { name: "豚肉", quantity: "200g", expiry: "明日" }
    ]

    message = "📝 現在の食材リスト\n\n"
    mock_ingredients.each do |ingredient|
      message += "• #{ingredient[:name]} (#{ingredient[:quantity]}) - 消費期限: #{ingredient[:expiry]}\n"
    end

    message += "\n🥕 食材の詳細管理はLIFFアプリをご利用ください！\n"
    message += "\n※現在はサンプルデータを表示しています。"

    @line_bot_service.create_text_message(message)
  end

  def create_shopping_list_message
    # 将来的には不足食材を自動で検出
    mock_shopping_items = [
      { name: "牛乳", reason: "冷蔵庫にありません" },
      { name: "卵", reason: "あと1個しかありません" },
      { name: "パン", reason: "明日で消費期限切れ" },
      { name: "醤油", reason: "残り少なくなっています" }
    ]

    message = "🛒 買い物リスト\n\n"
    mock_shopping_items.each do |item|
      message += "• #{item[:name]}\n  (#{item[:reason]})\n\n"
    end

    message += "💡 レシピに必要な食材も自動で追加予定です！\n"
    message += "\n※現在はサンプルデータを表示しています。"

    @line_bot_service.create_text_message(message)
  end

  def create_help_message
    @line_bot_service.create_text_message(
      "🆘 レコめしの使い方\n\n" \
      "📸 基本機能:\n" \
      "• 冷蔵庫の写真を送信 → 食材を自動認識\n" \
      "• 認識された食材からレシピを提案\n" \
      "• 不足食材の買い物リストを生成\n\n" \
      "💬 テキストコマンド:\n" \
      "• 「レシピ」「料理」→ レシピ提案\n" \
      "• 「食材」「在庫」→ 食材リスト\n" \
      "• 「買い物」→ 買い物リスト\n" \
      "• 「ヘルプ」→ この説明\n\n" \
      "🌐 詳細機能:\n" \
      "• LIFFアプリで食材の詳細管理\n" \
      "• Webアプリでより高度な機能\n\n" \
      "何かご不明な点があれば、いつでもお声かけください！"
    )
  end

  def create_unknown_message
    @line_bot_service.create_text_message(
      "メッセージありがとうございます！🙏\n\n" \
      "申し訳ございませんが、メッセージの内容を理解できませんでした。\n\n" \
      "📸 冷蔵庫の写真を送っていただければ、食材を認識してレシピを提案いたします！\n\n" \
      "また、以下のコマンドもご利用いただけます:\n" \
      "• 「レシピ」- レシピ提案\n" \
      "• 「食材」- 食材リスト\n" \
      "• 「買い物」- 買い物リスト\n" \
      "• 「ヘルプ」- 使い方説明"
    )
  end
end
