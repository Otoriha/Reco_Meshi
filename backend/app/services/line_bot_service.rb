class LineBotService
  require 'line/bot'

  def initialize
    @client = Line::Bot::Client.new do |config|
      config.channel_secret = Rails.application.credentials.line_channel_secret || ENV['LINE_CHANNEL_SECRET']
      config.channel_token = Rails.application.credentials.line_channel_access_token || ENV['LINE_CHANNEL_ACCESS_TOKEN']
    end
  end

  def validate_signature(body, signature)
    @client.validate_signature(body, signature)
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