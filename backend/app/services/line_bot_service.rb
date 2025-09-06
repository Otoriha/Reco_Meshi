require "line/bot"
require "openssl"
require "base64"

class LineBotService
  def initialize
  # V2 APIのMessaging APIクライアント
  @channel_secret = Rails.application.credentials.line_channel_secret || ENV["LINE_CHANNEL_SECRET"]
  @channel_token = Rails.application.credentials.line_channel_access_token || ENV["LINE_CHANNEL_ACCESS_TOKEN"]

  # V2 Messaging API Client
  @client = Line::Bot::V2::MessagingApi::ApiClient.new(
    channel_access_token: @channel_token
  )

  # V2 Blob API Client for content downloads
  @blob_client = Line::Bot::V2::MessagingApi::ApiBlobClient.new(
    channel_access_token: @channel_token
  )
end

  def parse_events_v2(raw_body, signature)
  Rails.logger.info "Using V2 WebhookParser: signature=#{signature.present? ? 'present' : 'missing'}, body_length=#{raw_body&.length}"
  Rails.logger.info "Channel secret: #{@channel_secret.present? ? 'present' : 'missing'}"

  parser = Line::Bot::V2::WebhookParser.new(channel_secret: @channel_secret)
  parser.parse(body: raw_body, signature: signature)
rescue Line::Bot::V2::WebhookParser::InvalidSignatureError => e
  Rails.logger.error "Signature validation failed: #{e.message}"
  raise e
rescue => e
  Rails.logger.error "Event parsing error: #{e.class}: #{e.message}"
  raise e
end

  def parse_events_from(body)
    @client.parse_events_from(body)
  end

  def reply_message(reply_token, message)
  # V2 MessagingApi用のリクエスト作成
  messages = if message.is_a?(Array)
    message.map { |msg| convert_to_v2_message(msg) }
  else
    [ convert_to_v2_message(message) ]
  end

  request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
    reply_token: reply_token,
    messages: messages
  )

  @client.reply_message(reply_message_request: request)
end

  private

  def convert_to_v2_message(message_hash)
  case message_hash[:type]
  when "text"
    Line::Bot::V2::MessagingApi::TextMessage.new(text: message_hash[:text])
  when "sticker"
    Line::Bot::V2::MessagingApi::StickerMessage.new(
      package_id: message_hash[:packageId],
      sticker_id: message_hash[:stickerId]
    )
  when "image"
    Line::Bot::V2::MessagingApi::ImageMessage.new(
      original_content_url: message_hash[:originalContentUrl],
      preview_image_url: message_hash[:previewImageUrl]
    )
  when "template"
    convert_template_to_v2_message(message_hash)
  when "flex"
    Line::Bot::V2::MessagingApi::FlexMessage.create(
      alt_text: message_hash[:altText],
      contents: underscore_keys(message_hash[:contents])
    )
  else
    raise ArgumentError, "Unsupported message type: #{message_hash[:type]}"
  end
end

  def convert_template_to_v2_message(message_hash)
    template = message_hash[:template]
    case template[:type]
    when "buttons"
      actions = template[:actions].map { |action| convert_action_to_v2(action) }
      Line::Bot::V2::MessagingApi::TemplateMessage.new(
        alt_text: message_hash[:altText] || template[:text] || "テンプレートメッセージ",
        template: Line::Bot::V2::MessagingApi::ButtonsTemplate.new(
          text: template[:text],
          actions: actions,
          title: template[:title],
          thumbnail_image_url: template[:thumbnailImageUrl]
        )
      )
    when "confirm"
      actions = template[:actions].map { |action| convert_action_to_v2(action) }
      Line::Bot::V2::MessagingApi::TemplateMessage.new(
        alt_text: message_hash[:altText] || template[:text] || "確認メッセージ",
        template: Line::Bot::V2::MessagingApi::ConfirmTemplate.new(
          text: template[:text],
          actions: actions
        )
      )
    when "carousel"
      columns = template[:columns].map do |column|
        actions = column[:actions].map { |action| convert_action_to_v2(action) }
        Line::Bot::V2::MessagingApi::CarouselColumn.new(
          text: column[:text],
          title: column[:title],
          thumbnail_image_url: column[:thumbnailImageUrl],
          actions: actions
        )
      end
      Line::Bot::V2::MessagingApi::TemplateMessage.new(
        alt_text: message_hash[:altText] || "カルーセルメッセージ",
        template: Line::Bot::V2::MessagingApi::CarouselTemplate.new(
          columns: columns
        )
      )
    else
      raise "Unsupported template type: #{template[:type]}"
    end
  end

  def convert_action_to_v2(action)
    case action[:type]
    when "postback"
      Line::Bot::V2::MessagingApi::PostbackAction.new(
        label: action[:label],
        data: action[:data],
        display_text: action[:displayText]
      )
    when "message"
      Line::Bot::V2::MessagingApi::MessageAction.new(
        label: action[:label],
        text: action[:text]
      )
    when "uri"
      Line::Bot::V2::MessagingApi::URIAction.new(
        label: action[:label],
        uri: action[:uri]
      )
    else
      raise "Unsupported action type: #{action[:type]}"
    end
  end

  public

  def push_message(user_id, message)
    # V2 MessagingApi用のリクエスト作成
    messages = if message.is_a?(Array)
      message.map { |msg| convert_to_v2_message(msg) }
    else
      [ convert_to_v2_message(message) ]
    end

    request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: user_id,
      messages: messages
    )

    @client.push_message(push_message_request: request)
  end

  def multicast_message(user_ids, message)
    # V2 MessagingApi用のリクエスト作成
    messages = if message.is_a?(Array)
      message.map { |msg| convert_to_v2_message(msg) }
    else
      [ convert_to_v2_message(message) ]
    end

    request = Line::Bot::V2::MessagingApi::MulticastRequest.new(
      to: user_ids,
      messages: messages
    )

    @client.multicast(multicast_request: request)
  end

  def get_profile(user_id)
    @client.get_profile(user_id)
  end

  def leave_group(group_id)
    @client.leave_group(group_id)
  end

  def leave_room(room_id)
    @client.leave_room(room_id)
  end

  def get_message_content(message_id)
    @blob_client.get_message_content(message_id: message_id)
  end

  def create_text_message(text)
    {
      type: "text",
      text: text
    }
  end

  def create_image_message(original_content_url, preview_image_url = nil)
    {
      type: "image",
      originalContentUrl: original_content_url,
      previewImageUrl: preview_image_url || original_content_url
    }
  end

  def create_template_message(alt_text, template)
    {
      type: "template",
      altText: alt_text,
      template: template
    }
  end

  def create_buttons_template(title, text, actions, thumbnail_image_url = nil)
    template = {
      type: "buttons",
      title: title,
      text: text,
      actions: actions
    }
    template[:thumbnailImageUrl] = thumbnail_image_url if thumbnail_image_url
    template
  end

  def create_confirm_template(text, actions)
    {
      type: "confirm",
      text: text,
      actions: actions
    }
  end

  def create_carousel_template(columns)
    {
      type: "carousel",
      columns: columns
    }
  end

  def create_postback_action(label, data, display_text = nil)
    action = {
      type: "postback",
      label: label,
      data: data
    }
    action[:displayText] = display_text if display_text
    action
  end

  def create_message_action(label, text)
    {
      type: "message",
      label: label,
      text: text
    }
  end

  def create_uri_action(label, uri)
    {
      type: "uri",
      label: label,
      uri: uri
    }
  end

  def create_quick_reply(items)
    {
      type: "quickReply",
      items: items
    }
  end

  def create_quick_reply_button(action, image_url = nil)
    button = {
      type: "action",
      action: action
    }
    button[:imageUrl] = image_url if image_url
    button
  end

  def create_flex_message(alt_text, contents)
    {
      type: "flex",
      altText: alt_text,
      contents: contents
    }
  end

  def create_flex_bubble(recipe_data)
    {
      type: "bubble",
      body: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: recipe_data[:title] || "おすすめレシピ",
            weight: "bold",
            size: "xl",
            wrap: true
          },
          {
            type: "box",
            layout: "baseline",
            margin: "md",
            contents: [
              {
                type: "text",
                text: "⏱ #{recipe_data[:time] || '約15分'}",
                flex: 1,
                size: "sm",
                color: "#666666"
              },
              {
                type: "text",
                text: recipe_data[:difficulty] || "★★☆",
                flex: 1,
                size: "sm",
                color: "#666666",
                align: "end"
              }
            ]
          },
          {
            type: "text",
            text: "材料:",
            weight: "bold",
            margin: "lg",
            size: "md"
          },
          *format_ingredients_for_flex(recipe_data[:ingredients] || []),
          {
            type: "text",
            text: recipe_data[:steps_summary] || "詳細はアプリでご確認ください",
            wrap: true,
            margin: "lg",
            color: "#666666",
            size: "sm"
          }
        ]
      },
      footer: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "button",
            action: {
              type: "uri",
              label: "詳しく見る",
              uri: generate_liff_url("/recipes")
            },
            style: "primary",
            color: "#42A5F5"
          }
        ]
      }
    }
  end

  def create_flex_carousel(recipes_data)
    bubbles = recipes_data.take(3).map { |recipe| create_flex_bubble(recipe) }
    {
      type: "carousel",
      contents: bubbles
    }
  end

  def generate_liff_url(path = nil)
    # LIFF_URLが設定されていればそれを使用、なければLIFF_IDから構築
    base_url = if ENV["LIFF_URL"].present?
                 ENV["LIFF_URL"]
    else
                 liff_id = ENV["LIFF_ID"] || ENV["VITE_LIFF_ID"]
                 raise ArgumentError, "LIFF_URL or LIFF_ID must be configured" if liff_id.blank?
                 "https://liff.line.me/#{liff_id}"
    end

    # パスが指定されている場合は結合、なければベースURLのみ
    if path.present?
      # パスの先頭スラッシュを正規化
      normalized_path = path.start_with?("/") ? path : "/#{path}"
      "#{base_url}#{normalized_path}"
    else
      base_url
    end
  end

  private

  def underscore_keys(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(k, v), acc|
        key = k.is_a?(String) || k.is_a?(Symbol) ? k.to_s.gsub(/([A-Z])/, '_\1').downcase.to_sym : k
        acc[key] = underscore_keys(v)
      end
    when Array
      obj.map { |e| underscore_keys(e) }
    else
      obj
    end
  end

  def format_ingredients_for_flex(ingredients)
    ingredients.take(5).map do |ingredient|
      name = ingredient.is_a?(Hash) ? (ingredient["name"] || ingredient[:name]) : ingredient.to_s
      amount = ingredient.is_a?(Hash) ? (ingredient["amount"] || ingredient[:amount]) : ""

      text = amount.present? ? "• #{name} #{amount}" : "• #{name}"

      {
        type: "text",
        text: text,
        size: "sm",
        color: "#333333"
      }
    end
  end

  attr_reader :client
end
