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
  case event
  when Line::Bot::V2::Webhook::MessageEvent
    case event.message
    when Line::Bot::V2::Webhook::TextMessageContent
      handle_text_message(event)
    when Line::Bot::V2::Webhook::ImageMessageContent
      handle_image_message(event)
    when Line::Bot::V2::Webhook::StickerMessageContent
      handle_sticker_message(event)
    end
  when Line::Bot::V2::Webhook::FollowEvent
    handle_follow_event(event)
  when Line::Bot::V2::Webhook::UnfollowEvent
    handle_unfollow_event(event)
  when Line::Bot::V2::Webhook::PostbackEvent
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

  # 画像認識処理をバックグラウンドジョブで実行予定
  # ImageRecognitionJob.perform_later(user_id, message_id, event.reply_token)

  # 暫定レスポンス
  response_message = line_bot_service.create_text_message("📸 画像を受信しました！\n\n現在、画像認識機能を開発中です。もうしばらくお待ちください🙏")
  line_bot_service.reply_message(event.reply_token, response_message)
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
      # ポストバックデータをコマンドにマッピング
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
