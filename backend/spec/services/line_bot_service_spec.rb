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
    it 'creates a LINE Bot V2 client with correct configuration' do
      expect(service.send(:client)).to be_a(Line::Bot::V2::MessagingApi::ApiClient)
    end

    it 'creates a LINE Bot V2 Blob client' do
      # プライベートインスタンス変数にアクセス
      blob_client = service.instance_variable_get(:@blob_client)
      expect(blob_client).to be_a(Line::Bot::V2::MessagingApi::ApiBlobClient)
    end
  end

  describe '#parse_events_v2' do
    let(:raw_body) { '{"events":[]}' }
    let(:signature) { 'valid_signature' }

    context 'with valid signature' do
      it 'parses events successfully' do
        mock_parser = double('Line::Bot::V2::WebhookParser')
        allow(Line::Bot::V2::WebhookParser).to receive(:new).and_return(mock_parser)
        allow(mock_parser).to receive(:parse).and_return([])

        result = service.parse_events_v2(raw_body, signature)

        expect(result).to eq([])
        expect(Line::Bot::V2::WebhookParser).to have_received(:new).with(channel_secret: line_channel_secret)
        expect(mock_parser).to have_received(:parse).with(body: raw_body, signature: signature)
      end
    end

    context 'with invalid signature' do
      it 'raises InvalidSignatureError' do
        allow(Line::Bot::V2::WebhookParser).to receive(:new).and_raise(
          Line::Bot::V2::WebhookParser::InvalidSignatureError.new('Invalid signature')
        )

        expect {
          service.parse_events_v2(raw_body, signature)
        }.to raise_error(Line::Bot::V2::WebhookParser::InvalidSignatureError)
      end
    end
  end

  describe '#reply_message' do
    let(:reply_token) { 'test_reply_token' }
    let(:text_message) { { type: 'text', text: 'Hello' } }

    it 'converts message and sends reply without error' do
      # V2テンプレートメッセージのconvert_to_v2_messageが正常に動作するかをテスト
      expect { service.reply_message(reply_token, text_message) }.not_to raise_error
    end
  end

  describe '#convert_to_v2_message' do
    context 'with text message' do
      it 'converts to V2 TextMessage' do
        message_hash = { type: 'text', text: 'Hello, World!' }

        result = service.send(:convert_to_v2_message, message_hash)

        expect(result).to be_a(Line::Bot::V2::MessagingApi::TextMessage)
        expect(result.text).to eq('Hello, World!')
      end
    end

    context 'with sticker message' do
      it 'converts to V2 StickerMessage' do
        message_hash = { type: 'sticker', packageId: '446', stickerId: '1988' }

        result = service.send(:convert_to_v2_message, message_hash)

        expect(result).to be_a(Line::Bot::V2::MessagingApi::StickerMessage)
        expect(result.package_id).to eq('446')
        expect(result.sticker_id).to eq('1988')
      end
    end

    context 'with image message' do
      it 'converts to V2 ImageMessage' do
        message_hash = {
          type: 'image',
          originalContentUrl: 'https://example.com/original.jpg',
          previewImageUrl: 'https://example.com/preview.jpg'
        }

        result = service.send(:convert_to_v2_message, message_hash)

        expect(result).to be_a(Line::Bot::V2::MessagingApi::ImageMessage)
        expect(result.original_content_url).to eq('https://example.com/original.jpg')
        expect(result.preview_image_url).to eq('https://example.com/preview.jpg')
      end
    end

    context 'with template message' do
      context 'buttons template' do
        it 'converts to V2 TemplateMessage with ButtonsTemplate' do
          message_hash = {
            type: 'template',
            altText: 'Buttons template',
            template: {
              type: 'buttons',
              text: 'Please choose',
              actions: [
                { type: 'message', label: 'Yes', text: 'yes' },
                { type: 'message', label: 'No', text: 'no' }
              ]
            }
          }

          result = service.send(:convert_to_v2_message, message_hash)

          expect(result).to be_a(Line::Bot::V2::MessagingApi::TemplateMessage)
          expect(result.alt_text).to eq('Buttons template')
          expect(result.template).to be_a(Line::Bot::V2::MessagingApi::ButtonsTemplate)
        end
      end

      context 'confirm template' do
        it 'converts to V2 TemplateMessage with ConfirmTemplate' do
          message_hash = {
            type: 'template',
            altText: 'Confirm template',
            template: {
              type: 'confirm',
              text: 'Are you sure?',
              actions: [
                { type: 'message', label: 'Yes', text: 'yes' },
                { type: 'message', label: 'No', text: 'no' }
              ]
            }
          }

          result = service.send(:convert_to_v2_message, message_hash)

          expect(result).to be_a(Line::Bot::V2::MessagingApi::TemplateMessage)
          expect(result.template).to be_a(Line::Bot::V2::MessagingApi::ConfirmTemplate)
        end
      end

      context 'carousel template' do
        it 'converts to V2 TemplateMessage with CarouselTemplate' do
          message_hash = {
            type: 'template',
            altText: 'Carousel template',
            template: {
              type: 'carousel',
              columns: [
                {
                  text: 'Column 1',
                  title: 'Title 1',
                  actions: [ { type: 'message', label: 'Select', text: 'selected' } ]
                }
              ]
            }
          }

          result = service.send(:convert_to_v2_message, message_hash)

          expect(result).to be_a(Line::Bot::V2::MessagingApi::TemplateMessage)
          expect(result.template).to be_a(Line::Bot::V2::MessagingApi::CarouselTemplate)
        end
      end
    end

    context 'with unsupported message type' do
      it 'raises an error' do
        message_hash = { type: 'unsupported' }

        expect {
          service.send(:convert_to_v2_message, message_hash)
        }.to raise_error('Unsupported message type: unsupported')
      end
    end
  end

  describe '#convert_action_to_v2' do
    context 'with postback action' do
      it 'converts to V2 PostbackAction' do
        action = { type: 'postback', label: 'Postback', data: 'action=postback' }

        result = service.send(:convert_action_to_v2, action)

        expect(result).to be_a(Line::Bot::V2::MessagingApi::PostbackAction)
        expect(result.label).to eq('Postback')
        expect(result.data).to eq('action=postback')
      end
    end

    context 'with message action' do
      it 'converts to V2 MessageAction' do
        action = { type: 'message', label: 'Message', text: 'Hello' }

        result = service.send(:convert_action_to_v2, action)

        expect(result).to be_a(Line::Bot::V2::MessagingApi::MessageAction)
        expect(result.label).to eq('Message')
        expect(result.text).to eq('Hello')
      end
    end

    context 'with URI action' do
      it 'converts to V2 UriAction' do
        action = { type: 'uri', label: 'Link', uri: 'https://example.com' }

        result = service.send(:convert_action_to_v2, action)

        expect(result).to be_a(Line::Bot::V2::MessagingApi::URIAction)
        expect(result.label).to eq('Link')
        expect(result.uri).to eq('https://example.com')
      end
    end

    context 'with unsupported action type' do
      it 'raises an error' do
        action = { type: 'unsupported' }

        expect {
          service.send(:convert_action_to_v2, action)
        }.to raise_error('Unsupported action type: unsupported')
      end
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
      template = { type: 'buttons', text: 'Please choose', actions: [] }

      message = service.create_template_message('Template message', template)

      expect(message).to eq({
        type: 'template',
        altText: 'Template message',
        template: template
      })
    end
  end

  describe '#create_buttons_template' do
    it 'creates a buttons template' do
      actions = [ { type: 'message', label: 'Yes', text: 'yes' } ]

      template = service.create_buttons_template('Title', 'Please choose', actions)

      expect(template).to eq({
        type: 'buttons',
        title: 'Title',
        text: 'Please choose',
        actions: actions
      })
    end

    context 'with thumbnail image URL' do
      it 'includes thumbnail image URL' do
        actions = [ { type: 'message', label: 'Yes', text: 'yes' } ]
        thumbnail_url = 'https://example.com/thumbnail.jpg'

        template = service.create_buttons_template('Title', 'Please choose', actions, thumbnail_url)

        expect(template[:thumbnailImageUrl]).to eq(thumbnail_url)
      end
    end
  end

  describe '#create_confirm_template' do
    it 'creates a confirm template' do
      actions = [
        { type: 'message', label: 'Yes', text: 'yes' },
        { type: 'message', label: 'No', text: 'no' }
      ]

      template = service.create_confirm_template('Are you sure?', actions)

      expect(template).to eq({
        type: 'confirm',
        text: 'Are you sure?',
        actions: actions
      })
    end
  end

  describe '#create_carousel_template' do
    it 'creates a carousel template' do
      columns = [
        { text: 'Column 1', actions: [] },
        { text: 'Column 2', actions: [] }
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
        action = service.create_postback_action('Label', 'data=value', 'Display Text')

        expect(action).to eq({
          type: 'postback',
          label: 'Label',
          data: 'data=value',
          displayText: 'Display Text'
        })
      end
    end

    context 'without display text' do
      it 'creates a postback action without display text' do
        action = service.create_postback_action('Label', 'data=value')

        expect(action).to eq({
          type: 'postback',
          label: 'Label',
          data: 'data=value'
        })
      end
    end
  end

  describe '#create_message_action' do
    it 'creates a message action' do
      action = service.create_message_action('Label', 'Message text')

      expect(action).to eq({
        type: 'message',
        label: 'Label',
        text: 'Message text'
      })
    end
  end

  describe '#create_uri_action' do
    it 'creates a URI action' do
      action = service.create_uri_action('Label', 'https://example.com')

      expect(action).to eq({
        type: 'uri',
        label: 'Label',
        uri: 'https://example.com'
      })
    end
  end

  describe '#create_quick_reply' do
    it 'creates a quick reply' do
      items = [ { type: 'action', action: { type: 'message', label: 'Yes', text: 'yes' } } ]

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
        action = { type: 'message', label: 'Yes', text: 'yes' }
        image_url = 'https://example.com/icon.png'

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
        action = { type: 'message', label: 'Yes', text: 'yes' }

        button = service.create_quick_reply_button(action)

        expect(button).to eq({
          type: 'action',
          action: action
        })
      end
    end
  end

  describe '#get_message_content' do
    let(:message_id) { 'test_message_123' }
    let(:image_content) { 'fake_image_binary_data' }
    let(:mock_blob_client) { instance_double(Line::Bot::V2::MessagingApi::ApiBlobClient) }

    before do
      allow(Line::Bot::V2::MessagingApi::ApiBlobClient).to receive(:new).and_return(mock_blob_client)
      service.instance_variable_set(:@blob_client, mock_blob_client)
    end

    context 'when blob client returns content successfully' do
      before do
        allow(mock_blob_client).to receive(:get_message_content)
          .with(message_id: message_id)
          .and_return(image_content)
      end

      it 'fetches message content using blob client' do
        result = service.get_message_content(message_id)

        expect(result).to eq(image_content)
        expect(mock_blob_client).to have_received(:get_message_content).with(message_id: message_id)
      end
    end
  end

  describe '#create_flex_message' do
    it 'creates a flex message hash' do
      alt_text = 'Flex message'
      contents = { type: 'bubble', body: { type: 'box', layout: 'vertical', contents: [] } }

      message = service.create_flex_message(alt_text, contents)

      expect(message).to eq({
        type: 'flex',
        altText: alt_text,
        contents: contents
      })
    end
  end

  describe '#create_flex_bubble' do
    let(:recipe_data) do
      {
        title: 'テストレシピ',
        time: '20分',
        difficulty: '★★☆',
        ingredients: [
          { name: '玉ねぎ', amount: '1個' },
          { name: '人参', amount: '1本' }
        ],
        steps_summary: '簡単に炒めるだけ'
      }
    end

    before do
      allow(ENV).to receive(:[]).with('LIFF_URL').and_return(nil)
      allow(ENV).to receive(:[]).with('LIFF_ID').and_return('test-liff-id')
      allow(ENV).to receive(:[]).with('VITE_LIFF_ID').and_return(nil)
    end

    it 'creates a bubble structure with recipe data' do
      bubble = service.create_flex_bubble(recipe_data)

      expect(bubble[:type]).to eq('bubble')
      expect(bubble[:body][:type]).to eq('box')
      expect(bubble[:body][:layout]).to eq('vertical')
      expect(bubble[:body][:contents]).to be_an(Array)
      expect(bubble[:footer][:type]).to eq('box')
      expect(bubble[:footer][:contents]).to be_an(Array)
    end

    it 'includes recipe title in the bubble' do
      bubble = service.create_flex_bubble(recipe_data)
      title_component = bubble[:body][:contents].first

      expect(title_component[:type]).to eq('text')
      expect(title_component[:text]).to eq('テストレシピ')
      expect(title_component[:weight]).to eq('bold')
    end

    it 'handles missing recipe data gracefully' do
      empty_data = {}
      bubble = service.create_flex_bubble(empty_data)

      title_component = bubble[:body][:contents].first
      expect(title_component[:text]).to eq('おすすめレシピ')
    end
  end

  describe '#create_flex_carousel' do
    let(:recipes_data) do
      [
        { title: 'レシピ1', time: '15分' },
        { title: 'レシピ2', time: '20分' },
        { title: 'レシピ3', time: '25分' },
        { title: 'レシピ4', time: '30分' } # 4つ目は制限により除外される
      ]
    end

    before do
      allow(ENV).to receive(:[]).with('LIFF_URL').and_return(nil)
      allow(ENV).to receive(:[]).with('LIFF_ID').and_return('test-liff-id')
      allow(ENV).to receive(:[]).with('VITE_LIFF_ID').and_return(nil)
    end

    it 'creates a carousel with maximum 3 bubbles' do
      carousel = service.create_flex_carousel(recipes_data)

      expect(carousel[:type]).to eq('carousel')
      expect(carousel[:contents]).to be_an(Array)
      expect(carousel[:contents].length).to eq(3)
    end

    it 'each bubble in carousel has correct structure' do
      carousel = service.create_flex_carousel(recipes_data)

      carousel[:contents].each do |bubble|
        expect(bubble[:type]).to eq('bubble')
        expect(bubble[:body]).to be_a(Hash)
        expect(bubble[:footer]).to be_a(Hash)
      end
    end
  end

  describe '#generate_liff_url' do
    context 'with LIFF_URL environment variable' do
      before do
        allow(ENV).to receive(:[]).with('LIFF_URL').and_return('https://custom-liff.line.me/123')
        allow(ENV).to receive(:[]).with('LIFF_ID').and_return('test-liff-id')
      end

      it 'uses LIFF_URL as base URL' do
        url = service.generate_liff_url
        expect(url).to eq('https://custom-liff.line.me/123')
      end

      it 'appends path when provided' do
        url = service.generate_liff_url('/recipes')
        expect(url).to eq('https://custom-liff.line.me/123/recipes')
      end

      it 'normalizes path without leading slash' do
        url = service.generate_liff_url('recipes')
        expect(url).to eq('https://custom-liff.line.me/123/recipes')
      end
    end

    context 'without LIFF_URL but with LIFF_ID' do
      before do
        allow(ENV).to receive(:[]).with('LIFF_URL').and_return(nil)
        allow(ENV).to receive(:[]).with('LIFF_ID').and_return('test-liff-id')
        allow(ENV).to receive(:[]).with('VITE_LIFF_ID').and_return(nil)
      end

      it 'constructs URL from LIFF_ID' do
        url = service.generate_liff_url
        expect(url).to eq('https://liff.line.me/test-liff-id')
      end

      it 'appends path when provided' do
        url = service.generate_liff_url('/recipes')
        expect(url).to eq('https://liff.line.me/test-liff-id/recipes')
      end
    end

    context 'without LIFF_URL or LIFF_ID' do
      before do
        allow(ENV).to receive(:[]).with('LIFF_URL').and_return(nil)
        allow(ENV).to receive(:[]).with('LIFF_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('VITE_LIFF_ID').and_return(nil)
      end

      it 'raises an error' do
        expect {
          service.generate_liff_url
        }.to raise_error(ArgumentError, 'LIFF_URL or LIFF_ID must be configured')
      end
    end
  end

  describe '#underscore_keys' do
    it 'converts camelCase keys to snake_case' do
      input = {
        'camelCaseKey' => 'value1',
        'anotherKey' => {
          'nestedCamelCase' => 'value2',
          'arrayValue' => [
            { 'itemKey' => 'value3' }
          ]
        }
      }

      result = service.send(:underscore_keys, input)

      expect(result).to eq({
        camel_case_key: 'value1',
        another_key: {
          nested_camel_case: 'value2',
          array_value: [
            { item_key: 'value3' }
          ]
        }
      })
    end

    it 'handles arrays correctly' do
      input = [
        { 'firstKey' => 'value1' },
        { 'secondKey' => 'value2' }
      ]

      result = service.send(:underscore_keys, input)

      expect(result).to eq([
        { first_key: 'value1' },
        { second_key: 'value2' }
      ])
    end

    it 'returns non-hash/array values as-is' do
      expect(service.send(:underscore_keys, 'string')).to eq('string')
      expect(service.send(:underscore_keys, 123)).to eq(123)
      expect(service.send(:underscore_keys, nil)).to eq(nil)
    end
  end

  describe '#convert_to_v2_message with flex type' do
    let(:flex_message_hash) do
      {
        type: 'flex',
        altText: 'Flex message',
        contents: {
          type: 'bubble',
          body: {
            type: 'box',
            layout: 'vertical',
            contents: [
              { type: 'text', text: 'Hello' }
            ]
          }
        }
      }
    end

    before do
      allow(Line::Bot::V2::MessagingApi::FlexMessage).to receive(:create).and_return(double('FlexMessage'))
    end

    it 'creates FlexMessage with underscored keys' do
      service.send(:convert_to_v2_message, flex_message_hash)

      expect(Line::Bot::V2::MessagingApi::FlexMessage).to have_received(:create).with(
        alt_text: 'Flex message',
        contents: hash_including(:type, :body)
      )
    end
  end

  describe '#push_message' do
    let(:user_id) { 'test_user_123' }
    let(:message) { { type: 'text', text: 'Test message' } }
    let(:mock_client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }
    let(:mock_request) { instance_double(Line::Bot::V2::MessagingApi::PushMessageRequest) }
    let(:mock_v2_message) { instance_double(Line::Bot::V2::MessagingApi::TextMessage) }

    before do
      allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(mock_client)
      service.instance_variable_set(:@client, mock_client)
    end

    context 'when sending a single message' do
      before do
        allow(Line::Bot::V2::MessagingApi::TextMessage).to receive(:new)
          .with(text: 'Test message')
          .and_return(mock_v2_message)

        allow(Line::Bot::V2::MessagingApi::PushMessageRequest).to receive(:new)
          .with(to: user_id, messages: [ mock_v2_message ])
          .and_return(mock_request)

        allow(mock_client).to receive(:push_message)
          .with(push_message_request: mock_request)
      end

      it 'creates V2 request and sends message' do
        service.push_message(user_id, message)

        expect(Line::Bot::V2::MessagingApi::PushMessageRequest).to have_received(:new)
          .with(to: user_id, messages: [ mock_v2_message ])
        expect(mock_client).to have_received(:push_message)
          .with(push_message_request: mock_request)
      end
    end
  end
end
