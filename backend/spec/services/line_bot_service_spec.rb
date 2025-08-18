require 'rails_helper'

RSpec.describe LineBotService, type: :service do
  let(:service) { described_class.new }
  let(:line_channel_secret) { 'test_channel_secret' }
  let(:line_channel_access_token) { 'test_access_token' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_SECRET').and_return(line_channel_secret)
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_ACCESS_TOKEN').and_return(line_channel_access_token)
  end

  describe '#initialize' do
    it 'creates a LINE Bot client with correct configuration' do
      expect(service.send(:client)).to be_a(Line::Bot::Client)
    end
  end

  describe '#create_text_message' do
    it 'creates a text message hash' do
      message = service.create_text_message('Hello, World!')
      
      expect(message).to eq({
        type: 'text',
        text: 'Hello, World!'
      })
    end
  end

  describe '#create_image_message' do
    context 'with preview image URL' do
      it 'creates an image message hash with preview' do
        original_url = 'https://example.com/original.jpg'
        preview_url = 'https://example.com/preview.jpg'
        
        message = service.create_image_message(original_url, preview_url)
        
        expect(message).to eq({
          type: 'image',
          originalContentUrl: original_url,
          previewImageUrl: preview_url
        })
      end
    end

    context 'without preview image URL' do
      it 'creates an image message hash using original URL as preview' do
        original_url = 'https://example.com/original.jpg'
        
        message = service.create_image_message(original_url)
        
        expect(message).to eq({
          type: 'image',
          originalContentUrl: original_url,
          previewImageUrl: original_url
        })
      end
    end
  end

  describe '#create_template_message' do
    it 'creates a template message hash' do
      alt_text = 'This is a template message'
      template = { type: 'buttons', title: 'Test' }
      
      message = service.create_template_message(alt_text, template)
      
      expect(message).to eq({
        type: 'template',
        altText: alt_text,
        template: template
      })
    end
  end

  describe '#create_buttons_template' do
    context 'with thumbnail image' do
      it 'creates a buttons template with thumbnail' do
        title = 'Test Title'
        text = 'Test Text'
        actions = [{ type: 'message', label: 'Test', text: 'test' }]
        thumbnail_url = 'https://example.com/thumb.jpg'
        
        template = service.create_buttons_template(title, text, actions, thumbnail_url)
        
        expect(template).to eq({
          type: 'buttons',
          title: title,
          text: text,
          actions: actions,
          thumbnailImageUrl: thumbnail_url
        })
      end
    end

    context 'without thumbnail image' do
      it 'creates a buttons template without thumbnail' do
        title = 'Test Title'
        text = 'Test Text'
        actions = [{ type: 'message', label: 'Test', text: 'test' }]
        
        template = service.create_buttons_template(title, text, actions)
        
        expect(template).to eq({
          type: 'buttons',
          title: title,
          text: text,
          actions: actions
        })
      end
    end
  end

  describe '#create_confirm_template' do
    it 'creates a confirm template' do
      text = 'Are you sure?'
      actions = [
        { type: 'message', label: 'Yes', text: 'yes' },
        { type: 'message', label: 'No', text: 'no' }
      ]
      
      template = service.create_confirm_template(text, actions)
      
      expect(template).to eq({
        type: 'confirm',
        text: text,
        actions: actions
      })
    end
  end

  describe '#create_carousel_template' do
    it 'creates a carousel template' do
      columns = [
        { title: 'Column 1', text: 'Text 1' },
        { title: 'Column 2', text: 'Text 2' }
      ]
      
      template = service.create_carousel_template(columns)
      
      expect(template).to eq({
        type: 'carousel',
        columns: columns
      })
    end
  end

  describe '#create_postback_action' do
    context 'with display text' do
      it 'creates a postback action with display text' do
        action = service.create_postback_action('Test Label', 'test_data', 'Display Text')
        
        expect(action).to eq({
          type: 'postback',
          label: 'Test Label',
          data: 'test_data',
          displayText: 'Display Text'
        })
      end
    end

    context 'without display text' do
      it 'creates a postback action without display text' do
        action = service.create_postback_action('Test Label', 'test_data')
        
        expect(action).to eq({
          type: 'postback',
          label: 'Test Label',
          data: 'test_data'
        })
      end
    end
  end

  describe '#create_message_action' do
    it 'creates a message action' do
      action = service.create_message_action('Test Label', 'test message')
      
      expect(action).to eq({
        type: 'message',
        label: 'Test Label',
        text: 'test message'
      })
    end
  end

  describe '#create_uri_action' do
    it 'creates a URI action' do
      action = service.create_uri_action('Test Label', 'https://example.com')
      
      expect(action).to eq({
        type: 'uri',
        label: 'Test Label',
        uri: 'https://example.com'
      })
    end
  end

  describe '#create_quick_reply' do
    it 'creates a quick reply' do
      items = [
        { type: 'action', action: { type: 'message', label: 'Yes', text: 'yes' } }
      ]
      
      quick_reply = service.create_quick_reply(items)
      
      expect(quick_reply).to eq({
        type: 'quickReply',
        items: items
      })
    end
  end

  describe '#create_quick_reply_button' do
    context 'with image URL' do
      it 'creates a quick reply button with image' do
        action = { type: 'message', label: 'Test', text: 'test' }
        image_url = 'https://example.com/image.jpg'
        
        button = service.create_quick_reply_button(action, image_url)
        
        expect(button).to eq({
          type: 'action',
          action: action,
          imageUrl: image_url
        })
      end
    end

    context 'without image URL' do
      it 'creates a quick reply button without image' do
        action = { type: 'message', label: 'Test', text: 'test' }
        
        button = service.create_quick_reply_button(action)
        
        expect(button).to eq({
          type: 'action',
          action: action
        })
      end
    end
  end

  describe 'LINE Bot API methods' do
    let(:mock_client) { instance_double(Line::Bot::Client) }

    before do
      allow(Line::Bot::Client).to receive(:new).and_return(mock_client)
    end

    describe '#validate_signature' do
      it 'delegates to client validate_signature' do
        body = 'test body'
        signature = 'test signature'
        
        expect(mock_client).to receive(:validate_signature).with(body, signature).and_return(true)
        
        result = service.validate_signature(body, signature)
        expect(result).to be true
      end
    end

    describe '#parse_events_from' do
      it 'delegates to client parse_events_from' do
        body = 'test body'
        events = ['event1', 'event2']
        
        expect(mock_client).to receive(:parse_events_from).with(body).and_return(events)
        
        result = service.parse_events_from(body)
        expect(result).to eq(events)
      end
    end

    describe '#reply_message' do
      it 'delegates to client reply_message' do
        reply_token = 'test_token'
        message = { type: 'text', text: 'test' }
        
        expect(mock_client).to receive(:reply_message).with(reply_token, message)
        
        service.reply_message(reply_token, message)
      end
    end

    describe '#push_message' do
      it 'delegates to client push_message' do
        user_id = 'test_user_id'
        message = { type: 'text', text: 'test' }
        
        expect(mock_client).to receive(:push_message).with(user_id, message)
        
        service.push_message(user_id, message)
      end
    end

    describe '#get_profile' do
      it 'delegates to client get_profile' do
        user_id = 'test_user_id'
        
        expect(mock_client).to receive(:get_profile).with(user_id)
        
        service.get_profile(user_id)
      end
    end

    describe '#get_message_content' do
      it 'delegates to client get_message_content' do
        message_id = 'test_message_id'
        
        expect(mock_client).to receive(:get_message_content).with(message_id)
        
        service.get_message_content(message_id)
      end
    end
  end
end