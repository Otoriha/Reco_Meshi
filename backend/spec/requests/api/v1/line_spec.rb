require 'rails_helper'

RSpec.describe "Api::V1::Line", type: :request do
  let(:line_channel_secret) { 'test_channel_secret' }
  let(:line_channel_access_token) { 'test_access_token' }
  let(:valid_signature) { 'valid_signature' }
  let(:invalid_signature) { 'invalid_signature' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_SECRET').and_return(line_channel_secret)
    allow(ENV).to receive(:[]).with('LINE_CHANNEL_ACCESS_TOKEN').and_return(line_channel_access_token)
  end

  describe "POST /api/v1/line/webhook" do
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'X-Line-Signature' => valid_signature
      }
    end

    let(:text_message_event) do
      {
        "events" => [
          {
            "type" => "message",
            "message" => {
              "type" => "text",
              "text" => "こんにちは"
            },
            "source" => {
              "userId" => "test_user_id",
              "type" => "user"
            },
            "replyToken" => "test_reply_token"
          }
        ]
      }.to_json
    end

    let(:image_message_event) do
      {
        "events" => [
          {
            "type" => "message",
            "message" => {
              "type" => "image",
              "id" => "test_message_id"
            },
            "source" => {
              "userId" => "test_user_id",
              "type" => "user"
            },
            "replyToken" => "test_reply_token"
          }
        ]
      }.to_json
    end

    let(:follow_event) do
      {
        "events" => [
          {
            "type" => "follow",
            "source" => {
              "userId" => "test_user_id",
              "type" => "user"
            },
            "replyToken" => "test_reply_token"
          }
        ]
      }.to_json
    end

    let(:postback_event) do
      {
        "events" => [
          {
            "type" => "postback",
            "postback" => {
              "data" => "recipe_request"
            },
            "source" => {
              "userId" => "test_user_id",
              "type" => "user"
            },
            "replyToken" => "test_reply_token"
          }
        ]
      }.to_json
    end

    context "with valid signature" do
      before do
        allow_any_instance_of(LineBotService).to receive(:validate_signature).and_return(true)
        allow_any_instance_of(LineBotService).to receive(:reply_message).and_return(double(code: '200'))
      end

      it "handles text message successfully" do
        allow_any_instance_of(LineBotService).to receive(:parse_events_from).and_return([
          double(
            'Line::Bot::Event::Message',
            class: Line::Bot::Event::Message,
            type: Line::Bot::Event::MessageType::Text,
            message: { 'text' => 'こんにちは' },
            'source' => { 'userId' => 'test_user_id' },
            '[]' => proc { |key| { 'userId' => 'test_user_id' }[key] if key == 'source' || 'test_reply_token' if key == 'replyToken' }
          )
        ])

        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end

      it "handles image message successfully" do
        allow_any_instance_of(LineBotService).to receive(:parse_events_from).and_return([
          double(
            'Line::Bot::Event::Message',
            class: Line::Bot::Event::Message,
            type: Line::Bot::Event::MessageType::Image,
            message: { 'id' => 'test_message_id' },
            'source' => { 'userId' => 'test_user_id' },
            '[]' => proc { |key| { 'userId' => 'test_user_id' }[key] if key == 'source' || 'test_reply_token' if key == 'replyToken' }
          )
        ])

        post '/api/v1/line/webhook', params: image_message_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end

      it "handles follow event successfully" do
        allow_any_instance_of(LineBotService).to receive(:parse_events_from).and_return([
          double(
            'Line::Bot::Event::Follow',
            class: Line::Bot::Event::Follow,
            'source' => { 'userId' => 'test_user_id' },
            '[]' => proc { |key| { 'userId' => 'test_user_id' }[key] if key == 'source' || 'test_reply_token' if key == 'replyToken' }
          )
        ])

        post '/api/v1/line/webhook', params: follow_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end

      it "handles postback event successfully" do
        allow_any_instance_of(LineBotService).to receive(:parse_events_from).and_return([
          double(
            'Line::Bot::Event::Postback',
            class: Line::Bot::Event::Postback,
            'postback' => { 'data' => 'recipe_request' },
            'source' => { 'userId' => 'test_user_id' },
            '[]' => proc { |key| 
              case key
              when 'source'
                { 'userId' => 'test_user_id' }
              when 'replyToken'
                'test_reply_token'
              when 'postback'
                { 'data' => 'recipe_request' }
              end
            }
          )
        ])

        post '/api/v1/line/webhook', params: postback_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end
    end

    context "with invalid signature" do
      let(:headers_with_invalid_signature) do
        {
          'Content-Type' => 'application/json',
          'X-Line-Signature' => invalid_signature
        }
      end

      before do
        allow_any_instance_of(LineBotService).to receive(:validate_signature).and_return(false)
      end

      it "returns bad request for invalid signature" do
        post '/api/v1/line/webhook', params: text_message_event, headers: headers_with_invalid_signature

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Invalid signature')
      end
    end

    context "without signature header" do
      let(:headers_without_signature) do
        { 'Content-Type' => 'application/json' }
      end

      it "returns bad request for missing signature" do
        post '/api/v1/line/webhook', params: text_message_event, headers: headers_without_signature

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing signature')
      end
    end

    context "when LINE Bot API error occurs" do
      before do
        allow_any_instance_of(LineBotService).to receive(:validate_signature).and_return(true)
        allow_any_instance_of(LineBotService).to receive(:parse_events_from).and_raise(Line::Bot::API::Error.new('LINE API Error'))
      end

      it "returns internal server error" do
        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('LINE Bot API Error')
      end
    end

    context "when general error occurs" do
      before do
        allow_any_instance_of(LineBotService).to receive(:validate_signature).and_return(true)
        allow_any_instance_of(LineBotService).to receive(:parse_events_from).and_raise(StandardError.new('General Error'))
      end

      it "returns internal server error" do
        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Internal server error')
      end
    end
  end
end