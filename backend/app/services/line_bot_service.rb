require 'line/bot'
require 'openssl'
require 'base64'

class LineBotService

  def initialize
  # V2 APIのMessaging APIクライアント
  @channel_secret = Rails.application.credentials.line_channel_secret || ENV['LINE_CHANNEL_SECRET']
  @channel_token = Rails.application.credentials.line_channel_access_token || ENV['LINE_CHANNEL_ACCESS_TOKEN']
  
  # V2 Messaging API Client
  @client = Line::Bot::V2::MessagingApi::ApiClient.new(
    channel_access_token: @channel_token
  )
end

  def parse_events_v2(raw_body, signature)
  Rails.logger.info "Using V2 WebhookParser: signature=#{signature.present? ? 'present' : 'missing'}, body_length=#{raw_body&.length}"
  Rails.logger.info "Channel secret: #{ENV['LINE_CHANNEL_SECRET'].present? ? 'present' : 'missing'}"
  
  parser = Line::Bot::V2::WebhookParser.new(channel_secret: ENV['LINE_CHANNEL_SECRET'])
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
    @client.reply_message(reply_token, message)
  end

  def push_message(user_id, message)
    @client.push_message(user_id, message)
  end

  def multicast_message(user_ids, message)
    @client.multicast(user_ids, message)
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
    @client.get_message_content(message_id)
  end

  def create_text_message(text)
    {
      type: 'text',
      text: text
    }
  end

  def create_image_message(original_content_url, preview_image_url = nil)
    {
      type: 'image',
      originalContentUrl: original_content_url,
      previewImageUrl: preview_image_url || original_content_url
    }
  end

  def create_template_message(alt_text, template)
    {
      type: 'template',
      altText: alt_text,
      template: template
    }
  end

  def create_buttons_template(title, text, actions, thumbnail_image_url = nil)
    template = {
      type: 'buttons',
      title: title,
      text: text,
      actions: actions
    }
    template[:thumbnailImageUrl] = thumbnail_image_url if thumbnail_image_url
    template
  end

  def create_confirm_template(text, actions)
    {
      type: 'confirm',
      text: text,
      actions: actions
    }
  end

  def create_carousel_template(columns)
    {
      type: 'carousel',
      columns: columns
    }
  end

  def create_postback_action(label, data, display_text = nil)
    action = {
      type: 'postback',
      label: label,
      data: data
    }
    action[:displayText] = display_text if display_text
    action
  end

  def create_message_action(label, text)
    {
      type: 'message',
      label: label,
      text: text
    }
  end

  def create_uri_action(label, uri)
    {
      type: 'uri',
      label: label,
      uri: uri
    }
  end

  def create_quick_reply(items)
    {
      type: 'quickReply',
      items: items
    }
  end

  def create_quick_reply_button(action, image_url = nil)
    button = {
      type: 'action',
      action: action
    }
    button[:imageUrl] = image_url if image_url
    button
  end

  private

  attr_reader :client
end