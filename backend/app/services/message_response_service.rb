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
    # 現在はモック食材。後続Issueでユーザー在庫と連携
    ingredients = [ "玉ねぎ", "人参", "じゃがいも", "豚肉" ]

    begin
      primary_provider = (Rails.application.config.x.llm.is_a?(Hash) ? Rails.application.config.x.llm[:provider] : Rails.application.config.x.llm&.provider)
      llm_service = Llm::Factory.build
      messages = PromptTemplateService.recipe_generation(ingredients: ingredients)
      result = llm_service.generate(messages: messages, response_format: :json)

      # 環境変数によるFlex切り替え
      if flex_enabled?
        create_flex_recipe_message(result.text)
      else
        text = format_recipe_text(result.text)
        @line_bot_service.create_text_message(text)
      end
    rescue => e
      Rails.logger.error "LLM API Error: #{e.message}"
      ActiveSupport::Notifications.instrument("llm.error", {
        provider: primary_provider,
        error_class: e.class.name,
        error_message: e.message
      })

      # プロバイダフォールバックが設定されていれば試行
      begin
        fallback = Rails.application.config.x.llm
        fallback_provider = fallback.is_a?(Hash) ? fallback[:fallback_provider] : fallback&.fallback_provider
        if fallback_provider && fallback_provider != (fallback.is_a?(Hash) ? fallback[:provider] : fallback&.provider)
          ActiveSupport::Notifications.instrument("llm.fallback", { from: primary_provider, to: fallback_provider })
          alt = Llm::Factory.build(provider: fallback_provider)
          messages = PromptTemplateService.recipe_generation(ingredients: ingredients)
          result = alt.generate(messages: messages, response_format: :json)

          # フォールバック時もFlex切り替えを適用
          return flex_enabled? ? create_flex_recipe_message(result.text) :
                                (@line_bot_service.create_text_message(format_recipe_text(result.text)))
        end
      rescue => e2
        Rails.logger.error "LLM Fallback Error: #{e2.message}"
        ActiveSupport::Notifications.instrument("llm.error", {
          provider: fallback_provider,
          error_class: e2.class.name,
          error_message: e2.message
        })
      end

      # 最終フォールバック：従来のモック文面
      create_fallback_recipe_message(ingredients)
    end
  end

  def format_recipe_text(json_text)
    data = JSON.parse(json_text) rescue nil
    return json_text unless data.is_a?(Hash)

    lines = []
    lines << "🍳 今ある食材でのレシピ提案"
    lines << ""
    lines << "📖 おすすめレシピ:"
    lines << "「#{data['title']}」" if data["title"]
    lines << "・調理時間: #{data['time']}" if data["time"]
    lines << "・難易度: #{data['difficulty']}" if data["difficulty"]
    if data["ingredients"].is_a?(Array)
      lines << ""
      lines << "材料:"
      data["ingredients"].each do |ing|
        name = ing["name"] || ing[:name]
        amount = ing["amount"] || ing[:amount]
        lines << "・#{[ name, amount ].compact.join(' ')}"
      end
    end
    if data["steps"].is_a?(Array)
      lines << ""
      lines << "作り方:"
      data["steps"].each_with_index do |step, idx|
        lines << "#{idx + 1}. #{step}"
      end
    end
    lines << ""
    lines << "詳しい作り方はLIFFアプリでご確認ください！"
    lines.join("\n")
  end

  def create_fallback_recipe_message(ingredients)
    @line_bot_service.create_text_message(
      "🍳 今ある食材でのレシピ提案\n\n" \
      "現在の食材: #{ingredients.join(', ')}\n\n" \
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

  def flex_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV["LINE_FLEX_ENABLED"])
  end

  def create_flex_recipe_message(json_text)
    data = JSON.parse(json_text) rescue {}

    title = data["title"].to_s.strip
    time = data["time"].to_s.strip
    diff = data["difficulty"].to_s.strip

    # 材料を整形（最大5件）
    ings = Array(data["ingredients"]).take(5).map do |h|
      name = (h["name"] || h[:name]).to_s.strip
      amount = (h["amount"] || h[:amount]).to_s.strip
      "・#{[ name, amount ].reject(&:empty?).join(' ')}"
    end

    # 手順を要約（最大3ステップ）
    steps = Array(data["steps"]).take(3).each_with_index.map { |s, i| "#{i + 1}. #{s}" }

    # altTextを400文字以内に制限
    alt = "[レシピ] #{title.empty? ? 'おすすめレシピ' : title}"
    alt = alt[0, 400]

    bubble = {
      type: "bubble",
      body: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: title.empty? ? "おすすめレシピ" : title,
            weight: "bold",
            size: "lg",
            wrap: true
          },
          {
            type: "box",
            layout: "baseline",
            margin: "md",
            contents: [
              {
                type: "text",
                text: "⏱ #{time.empty? ? '約15分' : time}",
                flex: 1,
                size: "sm",
                color: "#666666"
              },
              {
                type: "text",
                text: diff.empty? ? "★★☆" : diff,
                flex: 1,
                size: "sm",
                color: "#666666",
                align: "end"
              }
            ]
          }
        ]
      }
    }

    # 材料セクションを追加
    if ings.any?
      bubble[:body][:contents] << {
        type: "text",
        text: "材料",
        weight: "bold",
        size: "sm",
        margin: "lg"
      }
      bubble[:body][:contents] << {
        type: "text",
        text: ings.join("\n"),
        size: "sm",
        wrap: true,
        color: "#333333"
      }
    end

    # 作り方セクションを追加
    if steps.any?
      bubble[:body][:contents] << {
        type: "text",
        text: "作り方（要約）",
        weight: "bold",
        size: "sm",
        margin: "lg"
      }
      bubble[:body][:contents] << {
        type: "text",
        text: steps.join("\n"),
        size: "sm",
        wrap: true
      }
    end

    # フッターにLIFFリンクを追加
    bubble[:footer] = {
      type: "box",
      layout: "vertical",
      contents: [
        {
          type: "button",
          style: "primary",
          color: "#42A5F5",
          action: {
            type: "uri",
            label: "詳しく見る",
            uri: @line_bot_service.generate_liff_url("/recipes")
          }
        }
      ]
    }

    @line_bot_service.create_flex_message(alt, bubble)
  rescue JSON::ParserError => e
    Rails.logger.error "Flex message creation failed (JSON parse error): #{e.message}"
    # JSONパースエラー時はテキストメッセージにフォールバック
    @line_bot_service.create_text_message("申し訳ございませんが、レシピの生成に失敗しました。もう一度お試しください。")
  rescue => e
    Rails.logger.error "Flex message creation failed: #{e.message}"
    # その他のエラー時もテキストメッセージにフォールバック
    text = format_recipe_text(json_text)
    @line_bot_service.create_text_message(text)
  end
end
