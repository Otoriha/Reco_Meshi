class MessageResponseService
  def initialize(line_bot_service)
    @line_bot_service = line_bot_service
  end

  def generate_response(command, user_id = nil)
    case command
    when :greeting
      create_greeting_message
    when :recipe
      create_recipe_suggestion_message(user_id)
    when :ingredients
      create_ingredients_list_message(user_id)
    when :shopping
      create_shopping_list_message(user_id)
    when :help
      create_help_message
    when :unknown
      create_unknown_message
    else
      create_unknown_message
    end
  end

  private

  def resolve_user_from_line_id(line_user_id)
    LineUserResolver.resolve_user_from_line_id(line_user_id)
  end

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

  def create_recipe_suggestion_message(line_user_id = nil)
    # ユーザーの実際の在庫食材を取得
    user = resolve_user_from_line_id(line_user_id)

    unless user
      return @line_bot_service.create_text_message(
        "🍳 レシピ提案機能をご利用いただくには、まずアプリでアカウント登録を行ってください。\n\n" \
        "Webアプリまたは「ヘルプ」コマンドでLIFFアプリへのリンクをご確認ください。"
      )
    end

    # ユーザーの利用可能な食材を取得
    user_ingredients = user.user_ingredients
                          .joins(:ingredient)
                          .where(status: "available")
                          .includes(:ingredient)
                          .order("ingredients.name ASC")
                          .limit(20)

    if user_ingredients.empty?
      return @line_bot_service.create_text_message(
        "🍳 レシピを提案するための食材がありません。\n\n" \
        "冷蔵庫の写真を送っていただくか、LIFFアプリで食材を登録してください。"
      )
    end

    # 食材名の配列を作成
    ingredients = user_ingredients.map { |ui| ui.ingredient&.name }.compact

    begin
      primary_provider = (Rails.application.config.x.llm.is_a?(Hash) ? Rails.application.config.x.llm[:provider] : Rails.application.config.x.llm&.provider)
      llm_service = Llm::Factory.build
      messages = PromptTemplateService.recipe_generation(ingredients: ingredients)
      result = llm_service.generate(messages: messages, response_format: :json)

      # レシピをDBに保存
      recipe = save_recipe_to_db(user, result.text, ingredients)

      # 環境変数によるFlex切り替え
      if flex_enabled?
        create_flex_recipe_message(result.text, recipe)
      else
        text = format_recipe_text(result.text, recipe)
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

          # フォールバック時もレシピを保存してFlex切り替えを適用
          fallback_recipe = save_recipe_to_db(user, result.text, ingredients)
          return flex_enabled? ? create_flex_recipe_message(result.text, fallback_recipe) :
                                (@line_bot_service.create_text_message(format_recipe_text(result.text, fallback_recipe)))
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

  def format_recipe_text(json_text, recipe = nil)
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
    if recipe&.id
      lines << "詳しい作り方はLIFFアプリでご確認ください！"
      lines << @line_bot_service.generate_liff_url("/recipes/#{recipe.id}")
    else
      lines << "詳しい作り方はLIFFアプリでご確認ください！"
    end
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

  def create_ingredients_list_message(line_user_id = nil)
    user = resolve_user_from_line_id(line_user_id)

    unless user
      return @line_bot_service.create_text_message(
        "📝 食材リスト機能をご利用いただくには、まずアプリでアカウント登録を行ってください。\n\n" \
        "Webアプリまたは「ヘルプ」コマンドでLIFFアプリへのリンクをご確認ください。"
      )
    end

    # ユーザーの食材リストを取得（利用可能なもののみ）
    user_ingredients = user.user_ingredients
                          .joins(:ingredient)
                          .where(status: "available")
                          .includes(:ingredient)
                          .order("ingredients.name ASC")
                          .limit(20) # 表示件数制限

    if user_ingredients.empty?
      return @line_bot_service.create_text_message(
        "📝 現在、登録されている食材がありません。\n\n" \
        "冷蔵庫の写真を送っていただくか、LIFFアプリで食材を登録してください。"
      )
    end

    message = "📝 現在の食材リスト\n\n"

    user_ingredients.each do |user_ingredient|
      ingredient_name = user_ingredient.ingredient&.name || "不明な食材"
      quantity = user_ingredient.quantity.present? ? " #{format_quantity(user_ingredient.quantity)}" : ""
      unit = user_ingredient.ingredient&.unit.present? ? "#{user_ingredient.ingredient.unit}" : ""

      # 消費期限の表示
      expiry_info = ""
      if user_ingredient.expiry_date
        days_until_expiry = (user_ingredient.expiry_date - Date.current).to_i
        if days_until_expiry <= 0
          expiry_info = " - ⚠️消費期限切れ"
        elsif days_until_expiry <= 3
          expiry_info = " - ⚠️#{days_until_expiry}日後まで"
        elsif days_until_expiry <= 7
          expiry_info = " - #{days_until_expiry}日後まで"
        end
      end

      message += "• #{ingredient_name}#{quantity}#{unit}#{expiry_info}\n"
    end

    if user.user_ingredients.where(status: "available").count > 20
      message += "\n...他#{user.user_ingredients.where(status: 'available').count - 20}件\n"
    end

    message += "\n🥕 食材の詳細管理はLIFFアプリをご利用ください！"

    @line_bot_service.create_text_message(message)
  rescue => e
    Rails.logger.error "Ingredients list message generation error: #{e.class}: #{e.message}"
    @line_bot_service.create_text_message(
      "申し訳ございません。食材リストの取得中にエラーが発生しました。\n\n" \
      "しばらく時間をおいてから再度お試しください。"
    )
  end

  def create_shopping_list_message(line_user_id = nil)
    user = resolve_user_from_line_id(line_user_id)

    unless user
      return @line_bot_service.create_text_message(
        "🛒 買い物リスト機能をご利用いただくには、まずアプリでアカウント登録を行ってください。\n\n" \
        "Webアプリまたは「ヘルプ」コマンドでLIFFアプリへのリンクをご確認ください。"
      )
    end

    # 最新のアクティブな買い物リストを取得
    shopping_list = user.shopping_lists
                       .includes(shopping_list_items: :ingredient)
                       .active
                       .recent
                       .first

    unless shopping_list
      return @line_bot_service.create_text_message(
        "🛒 現在、アクティブな買い物リストがありません。\n\n" \
        "レシピを提案してもらうか、LIFFアプリで買い物リストを作成してください。"
      )
    end

    # 環境変数によるFlex切り替え
    if flex_enabled?
      create_flex_shopping_list_message(shopping_list)
    else
      create_text_shopping_list_message(shopping_list)
    end
  rescue => e
    Rails.logger.error "Shopping list message generation error: #{e.class}: #{e.message}"
    @line_bot_service.create_text_message(
      "申し訳ございません。買い物リストの取得中にエラーが発生しました。\n\n" \
      "しばらく時間をおいてから再度お試しください。"
    )
  end

  def create_text_shopping_list_message(shopping_list)
    # ShoppingListMessageServiceを使用してテキストメッセージを生成
    message_service = ShoppingListMessageService.new(@line_bot_service)
    message_service.generate_text_message(shopping_list)
  end

  def create_flex_shopping_list_message(shopping_list)
    # ShoppingListMessageServiceを使用してFlexメッセージを生成
    message_service = ShoppingListMessageService.new(@line_bot_service)
    message_service.generate_flex_message(shopping_list)
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
    # Ensure nil casts to false
    !!ActiveModel::Type::Boolean.new.cast(ENV["LINE_FLEX_ENABLED"])
  end

  def create_flex_recipe_message(json_text, recipe = nil)
    data = JSON.parse(json_text)

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
      ings.each do |line|
        bubble[:body][:contents] << {
          type: "text",
          text: line,
          size: "sm",
          wrap: true,
          color: "#333333"
        }
      end
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

    # フッターにLIFFリンクを追加（レシピIDがあれば詳細ページへ）
    liff_url = if recipe&.id
                 @line_bot_service.generate_liff_url("/recipes/#{recipe.id}")
               else
                 @line_bot_service.generate_liff_url("/recipes")
               end

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
            uri: liff_url
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
    text = format_recipe_text(json_text, recipe)
    @line_bot_service.create_text_message(text)
  end

  private

  def format_quantity(quantity)
    return quantity.to_s if quantity.nil?

    if quantity % 1 == 0
      quantity.to_i.to_s
    else
      quantity.to_s
    end
  end

  def save_recipe_to_db(user, json_text, used_ingredients)
    data = JSON.parse(json_text)

    # 調理時間を分単位に変換
    cooking_time = extract_cooking_time(data["time"])

    # 難易度を正規化
    difficulty = normalize_difficulty(data["difficulty"])

    # AIプロバイダーを取得
    provider_config = Rails.application.config.x.llm
    ai_provider = provider_config.is_a?(Hash) ? provider_config[:provider] : provider_config&.provider
    ai_provider ||= "openai"

    # トランザクションでレシピと食材を一括作成
    recipe = ActiveRecord::Base.transaction do
      # レシピ作成
      new_recipe = Recipe.create!(
        user: user,
        title: data["title"].to_s.strip.presence || "おすすめレシピ",
        cooking_time: cooking_time,
        difficulty: difficulty,
        steps: Array(data["steps"]),
        ai_provider: ai_provider,
        servings: data["servings"] || 2
      )

      # レシピ食材を作成
      Array(data["ingredients"]).each do |ing_data|
        name = (ing_data["name"] || ing_data[:name]).to_s.strip
        amount_str = (ing_data["amount"] || ing_data[:amount]).to_s.strip

        next if name.blank?

        # 食材マスタから検索
        ingredient = Ingredient.find_by("LOWER(name) = ?", name.downcase) ||
                     Ingredient.find_by("name ILIKE ?", "%#{name}%")

        # 数量と単位をパース
        amount, unit = parse_amount_and_unit(amount_str)

        RecipeIngredient.create!(
          recipe: new_recipe,
          ingredient: ingredient,
          ingredient_name: name,
          amount: amount,
          unit: unit,
          is_optional: false
        )
      end

      new_recipe
    end

    recipe
  rescue JSON::ParserError => e
    Rails.logger.error "Recipe save failed (JSON parse error): #{e.message}"
    nil
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Recipe save failed (validation error): #{e.message}"
    nil
  rescue => e
    Rails.logger.error "Recipe save failed: #{e.class}: #{e.message}"
    nil
  end

  def extract_cooking_time(time_str)
    return 30 if time_str.blank?

    # "約15分", "15分", "1時間30分" などをパース
    time_str = time_str.to_s
    hours = time_str.match(/(\d+)時間/)&.captures&.first.to_i || 0
    minutes = time_str.match(/(\d+)分/)&.captures&.first.to_i || 0

    total_minutes = (hours * 60) + minutes
    total_minutes > 0 ? total_minutes : 30
  end

  def normalize_difficulty(diff_str)
    return nil if diff_str.blank?

    diff_str = diff_str.to_s.downcase
    # 長い文字列から先に判定（★★★、★★、★の順）
    return "hard" if diff_str.include?("hard") || diff_str.include?("難しい") || diff_str.include?("★★★")
    return "medium" if diff_str.include?("medium") || diff_str.include?("普通") || diff_str.include?("★★")
    return "easy" if diff_str.include?("easy") || diff_str.include?("簡単") || diff_str.include?("★")

    nil
  end

  def parse_amount_and_unit(amount_str)
    return [ nil, nil ] if amount_str.blank?

    # "2個", "100g", "大さじ1" などをパース
    match = amount_str.match(/^([\d.]+)(.*)$/)
    return [ nil, amount_str ] unless match

    amount = match[1].to_f
    unit = match[2].strip.presence

    [ amount, unit ]
  end
end
