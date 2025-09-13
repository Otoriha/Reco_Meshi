class Api::V1::LineController < ApplicationController
  skip_before_action :authenticate_user!, only: :webhook

  def webhook
  raw_body = request.raw_post
  signature = request.get_header("HTTP_X_LINE_SIGNATURE")

  # 署名ヘッダーが存在しない場合は400エラーを返す
  if signature.blank?
    render json: { error: "Missing signature" }, status: :bad_request
    return
  end

  begin
    events = line_bot_service.parse_events_v2(raw_body, signature)

    events.each do |event|
      handle_event(event)
    end

    render json: { status: "ok" }
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    render json: { error: "Invalid signature" }, status: :unauthorized
  rescue => e
    Rails.logger.error "Webhook Error: #{e.class}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace&.first(5)&.join(', ')}"
    render json: { error: "Internal server error" }, status: :internal_server_error
  end
end

  private

  def handle_event(event)
  if event.is_a?(Line::Bot::V2::Webhook::MessageEvent)
    case event.message
    when Line::Bot::V2::Webhook::TextMessageContent
      handle_text_message(event)
    when Line::Bot::V2::Webhook::ImageMessageContent
      handle_image_message(event)
    when Line::Bot::V2::Webhook::StickerMessageContent
      handle_sticker_message(event)
    end
  elsif event.is_a?(Line::Bot::V2::Webhook::FollowEvent)
    handle_follow_event(event)
  elsif event.is_a?(Line::Bot::V2::Webhook::UnfollowEvent)
    handle_unfollow_event(event)
  elsif event.is_a?(Line::Bot::V2::Webhook::PostbackEvent) || event.respond_to?(:postback)
    handle_postback_event(event)
  end
end

  def handle_text_message(event)
    user_id = event.source.user_id
    message_text = event.message.text

    Rails.logger.info "Received text message from #{user_id}: #{message_text}"

    begin
      Rails.logger.info "=== DEBUG: Creating MessageAnalyzerService ==="
      analyzer = MessageAnalyzerService.new(message_text)
      Rails.logger.info "=== DEBUG: Analyzing message ==="
      command = analyzer.analyze
      Rails.logger.info "=== DEBUG: Command result: #{command} ==="

      Rails.logger.info "=== DEBUG: Creating MessageResponseService ==="
      response_generator = MessageResponseService.new(line_bot_service)
      Rails.logger.info "=== DEBUG: Generating response ==="
      response_message = response_generator.generate_response(command, user_id)
      Rails.logger.info "=== DEBUG: Response generated: #{response_message.inspect} ==="

      Rails.logger.info "=== DEBUG: Sending reply ==="
      response_result = line_bot_service.reply_message(event.reply_token, response_message)
      Rails.logger.info "=== DEBUG: LINE API Response: #{response_result.inspect} ==="
      Rails.logger.info "=== DEBUG: Reply sent successfully ==="
    rescue => e
      Rails.logger.error "Text message handling error: #{e.class}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace&.first(3)&.join(', ')}"

      # エラー時のフォールバック応答
      fallback_message = line_bot_service.create_text_message(
        "申し訳ございません。一時的にエラーが発生しました。\n\nもう一度お試しください。"
      )
      line_bot_service.reply_message(event.reply_token, fallback_message)
    end
  end

  def handle_image_message(event)
  user_id = event.source.user_id
  message_id = event.message.id

  Rails.logger.info "Received image message from #{user_id}: #{message_id}"

  # 即時ACK返信
  response_message = line_bot_service.create_text_message(
    "📸 画像を受信しました！\n\n" \
    "🔍 食材を解析中です。少々お待ちください..."
  )
  line_bot_service.reply_message(event.reply_token, response_message)

  # 画像認識処理をバックグラウンドジョブで実行
  ImageRecognitionJob.perform_later(user_id, message_id)
end

  def handle_sticker_message(event)
  # スタンプメッセージへの対応
  sticker_message = {
    type: "sticker",
    packageId: "446",
    stickerId: "1988"
  }

  line_bot_service.reply_message(event.reply_token, sticker_message)
end

  def handle_follow_event(event)
  user_id = event.source.user_id
  Rails.logger.info "New follower: #{user_id}"

  welcome_message = line_bot_service.create_text_message(
    "友だち追加ありがとうございます！🎉\n\n" \
    "レコめしは、冷蔵庫の写真から食材を認識して、最適なレシピを提案するAI食材管理アプリです。\n\n" \
    "📸 冷蔵庫の写真を送ってみてください！\n" \
    "🍽️ 今ある食材で作れるレシピを提案します\n" \
    "📝 必要な買い物リストも自動生成\n\n" \
    "まずは「ヘルプ」と送ってみてください！"
  )

  line_bot_service.reply_message(event.reply_token, welcome_message)
end

  def handle_unfollow_event(event)
  user_id = event.source.user_id
  Rails.logger.info "User unfollowed: #{user_id}"
  # ユーザーのブロック解除処理など
end

  def handle_postback_event(event)
    user_id = event.source.user_id
    postback_data = event.postback.data

    Rails.logger.info "Received postback from #{user_id}: #{postback_data}"

    begin
      # ポストバックデータを解析
      if postback_data.match?(/^check_item:(\d+):(\d+)$/)
        handle_check_item_postback(event, user_id, postback_data)
      elsif postback_data.match?(/^complete_list:(\d+)$/)
        handle_complete_list_postback(event, user_id, postback_data)
      else
        # 従来のコマンドにマッピング
        command = case postback_data
        when "recipe_request"
          :recipe
        when "ingredients_list"
          :ingredients
        when "shopping_list"
          :shopping
        when "help"
          :help
        else
          :unknown
        end

        # 応答メッセージ生成
        response_generator = MessageResponseService.new(line_bot_service)
        response_message = response_generator.generate_response(command, user_id)

        # メッセージ送信
        line_bot_service.reply_message(event.reply_token, response_message)
      end
    rescue => e
      Rails.logger.error "Postback handling error: #{e.class}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace&.first(3)&.join(', ')}"

      # エラー時のフォールバック応答
      fallback_message = line_bot_service.create_text_message(
        "申し訳ございません。一時的にエラーが発生しました。\n\nもう一度お試しください。"
      )
      line_bot_service.reply_message(event.reply_token, fallback_message)
    end
  end

  def handle_check_item_postback(event, user_id, postback_data)
    # postback_data: "check_item:#{shopping_list_id}:#{item_id}"
    match_data = postback_data.match(/^check_item:(\d+):(\d+)$/)
    shopping_list_id = match_data[1].to_i
    item_id = match_data[2].to_i

    # ユーザー解決
    user = resolve_user_from_line_id(user_id)
    unless user
      fallback_message = line_bot_service.create_text_message(
        "申し訳ございません。ユーザー情報を確認できませんでした。\n\n" \
        "アカウント登録を行ってからご利用ください。"
      )
      return line_bot_service.reply_message(event.reply_token, fallback_message)
    end

    # 買い物リストの権限確認
    shopping_list = user.shopping_lists.find_by(id: shopping_list_id)
    unless shopping_list
      liff_url = line_bot_service.generate_liff_url("/shopping-lists")
      fallback_message = line_bot_service.create_text_message(
        "申し訳ございません。指定された買い物リストが見つかりませんでした。\n\n" \
        "最新の買い物リストはLIFFアプリでご確認ください。\n" \
        "#{liff_url}"
      )
      return line_bot_service.reply_message(event.reply_token, fallback_message)
    end

    # アイテムの確認とトグル
    shopping_list_item = shopping_list.shopping_list_items.find_by(id: item_id)
    unless shopping_list_item
      fallback_message = line_bot_service.create_text_message(
        "申し訳ございません。指定されたアイテムが見つかりませんでした。"
      )
      return line_bot_service.reply_message(event.reply_token, fallback_message)
    end

    # チェック状態をトグル
    shopping_list_item.toggle_checked!
    Rails.logger.info "Toggled shopping list item #{item_id} to #{shopping_list_item.is_checked} for user #{user.id}"

    # リストの完了状態を確認
    shopping_list.reload
    if shopping_list.can_be_completed? && shopping_list.status_pending?
      shopping_list.mark_as_completed!
    end

    # 更新された買い物リストを再送信
    send_updated_shopping_list(event.reply_token, shopping_list)

  rescue => e
    Rails.logger.error "Check item postback error: #{e.class}: #{e.message}"
    fallback_message = line_bot_service.create_text_message(
      "申し訳ございません。処理中にエラーが発生しました。\n\n" \
      "もう一度お試しください。"
    )
    line_bot_service.reply_message(event.reply_token, fallback_message)
  end

  def handle_complete_list_postback(event, user_id, postback_data)
    # postback_data: "complete_list:#{shopping_list_id}"
    match_data = postback_data.match(/^complete_list:(\d+)$/)
    shopping_list_id = match_data[1].to_i

    # ユーザー解決
    user = resolve_user_from_line_id(user_id)
    unless user
      fallback_message = line_bot_service.create_text_message(
        "申し訳ございません。ユーザー情報を確認できませんでした。\n\n" \
        "アカウント登録を行ってからご利用ください。"
      )
      return line_bot_service.reply_message(event.reply_token, fallback_message)
    end

    # 買い物リストの権限確認
    shopping_list = user.shopping_lists.find_by(id: shopping_list_id)
    unless shopping_list
      liff_url = line_bot_service.generate_liff_url("/shopping-lists")
      fallback_message = line_bot_service.create_text_message(
        "申し訳ございません。指定された買い物リストが見つかりませんでした。\n\n" \
        "最新の買い物リストはLIFFアプリでご確認ください。\n" \
        "#{liff_url}"
      )
      return line_bot_service.reply_message(event.reply_token, fallback_message)
    end

    # 全アイテムをチェック済みに（コールバックを実行してchecked_atも更新）
    shopping_list.shopping_list_items.unchecked.find_each(&:mark_as_checked!)
    
    # リストを完了状態に
    shopping_list.mark_as_completed!
    Rails.logger.info "Completed shopping list #{shopping_list_id} for user #{user.id}"

    # 完了メッセージを送信
    completion_message = line_bot_service.create_text_message(
      "🎉 お疲れさまでした！\n\n" \
      "「#{shopping_list.display_title}」の買い物が完了しました。\n\n" \
      "新しいレシピ提案や買い物リストが必要でしたら、いつでもお声かけください！"
    )
    line_bot_service.reply_message(event.reply_token, completion_message)

  rescue => e
    Rails.logger.error "Complete list postback error: #{e.class}: #{e.message}"
    fallback_message = line_bot_service.create_text_message(
      "申し訳ございません。処理中にエラーが発生しました。\n\n" \
      "もう一度お試しください。"
    )
    line_bot_service.reply_message(event.reply_token, fallback_message)
  end

  def resolve_user_from_line_id(line_user_id)
    return nil if line_user_id.blank?
    
    line_account = LineAccount.find_by(line_user_id: line_user_id)
    line_account&.user
  end

  def send_updated_shopping_list(reply_token, shopping_list)
    # 環境変数によるFlex切り替え
    message_service = ShoppingListMessageService.new(line_bot_service)
    response_message = if flex_enabled?
      message_service.generate_flex_message(shopping_list)
    else
      message_service.generate_text_message(shopping_list)
    end

    line_bot_service.reply_message(reply_token, response_message)
  end

  def flex_enabled?
    # Ensure nil casts to false
    !!ActiveModel::Type::Boolean.new.cast(ENV["LINE_FLEX_ENABLED"])
  end


  def create_help_message
    # 新しいMessageResponseServiceを使用するため、このメソッドは不要
    # しかし、テンプレートメッセージ用に残しておく
    template = line_bot_service.create_buttons_template(
      "レコめしの使い方",
      "どちらの機能をお試しになりますか？",
      [
        line_bot_service.create_postback_action("📸 レシピ提案", "recipe_request", "レシピを提案して"),
        line_bot_service.create_postback_action("📝 食材リスト", "ingredients_list", "食材リストを見せて"),
        line_bot_service.create_postback_action("🛒 買い物リスト", "shopping_list", "買い物リストを見せて"),
        line_bot_service.create_uri_action("🌐 Webアプリ", ENV["FRONTEND_URL"] || "https://reco-meshiweb.vercel.app")
      ]
    )

    line_bot_service.create_template_message("レコめしの使い方", template)
  end

  def line_bot_service
    @line_bot_service ||= LineBotService.new
  end
end
