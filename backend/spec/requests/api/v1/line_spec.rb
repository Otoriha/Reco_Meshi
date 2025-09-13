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

    let(:sticker_message_event) do
      {
        "events" => [
          {
            "type" => "message",
            "message" => {
              "type" => "sticker",
              "packageId" => "446",
              "stickerId" => "1988"
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

    let(:unfollow_event) do
      {
        "events" => [
          {
            "type" => "unfollow",
            "source" => {
              "userId" => "test_user_id",
              "type" => "user"
            }
          }
        ]
      }.to_json
    end

    # V2 API用のモックイベント作成ヘルパー
    def create_v2_text_message_event(text = "こんにちは")
      # doubleを使用してモックオブジェクトを作成
      text_message = double('Line::Bot::V2::Webhook::TextMessageContent')
      allow(text_message).to receive(:text).and_return(text)

      source = double('Line::Bot::V2::Webhook::UserSource')
      allow(source).to receive(:user_id).and_return("test_user_id")

      event = double('Line::Bot::V2::Webhook::MessageEvent')
      allow(event).to receive(:message).and_return(text_message)
      allow(event).to receive(:source).and_return(source)
      allow(event).to receive(:reply_token).and_return("test_reply_token")
      event
    end

    def create_v2_image_message_event
      # doubleを使用してモックオブジェクトを作成
      image_message = double('Line::Bot::V2::Webhook::ImageMessageContent')
      allow(image_message).to receive(:id).and_return("test_message_id")

      source = double('Line::Bot::V2::Webhook::UserSource')
      allow(source).to receive(:user_id).and_return("test_user_id")

      event = double('Line::Bot::V2::Webhook::MessageEvent')
      allow(event).to receive(:message).and_return(image_message)
      allow(event).to receive(:source).and_return(source)
      allow(event).to receive(:reply_token).and_return("test_reply_token")
      event
    end

    def create_v2_sticker_message_event
      # doubleを使用してモックオブジェクトを作成
      sticker_message = double('Line::Bot::V2::Webhook::StickerMessageContent')
      allow(sticker_message).to receive(:package_id).and_return("446")
      allow(sticker_message).to receive(:sticker_id).and_return("1988")

      source = double('Line::Bot::V2::Webhook::UserSource')
      allow(source).to receive(:user_id).and_return("test_user_id")

      event = double('Line::Bot::V2::Webhook::MessageEvent')
      allow(event).to receive(:message).and_return(sticker_message)
      allow(event).to receive(:source).and_return(source)
      allow(event).to receive(:reply_token).and_return("test_reply_token")
      event
    end

    def create_v2_follow_event
      # doubleを使用してモックオブジェクトを作成
      source = double('Line::Bot::V2::Webhook::UserSource')
      allow(source).to receive(:user_id).and_return("test_user_id")

      event = double('Line::Bot::V2::Webhook::FollowEvent')
      allow(event).to receive(:source).and_return(source)
      allow(event).to receive(:reply_token).and_return("test_reply_token")
      event
    end

    def create_v2_unfollow_event
      # doubleを使用してモックオブジェクトを作成
      source = double('Line::Bot::V2::Webhook::UserSource')
      allow(source).to receive(:user_id).and_return("test_user_id")

      event = double('Line::Bot::V2::Webhook::UnfollowEvent')
      allow(event).to receive(:source).and_return(source)
      event
    end

    def create_v2_postback_event(data = "recipe_request")
      # Line::Bot::V2::Webhook::PostbackEventのモックを作成
      postback = double('PostbackContent')
      allow(postback).to receive(:data).and_return(data)

      source = double('UserSource')
      allow(source).to receive(:user_id).and_return("test_user_id")

      event = double('PostbackEvent')
      allow(event).to receive(:postback).and_return(postback)
      allow(event).to receive(:source).and_return(source)
      allow(event).to receive(:reply_token).and_return("test_reply_token")
      
      # すべてのクラスチェックをスタブ
      allow(event).to receive(:is_a?).with(Line::Bot::V2::Webhook::MessageEvent).and_return(false)
      allow(event).to receive(:is_a?).with(Line::Bot::V2::Webhook::FollowEvent).and_return(false)
      allow(event).to receive(:is_a?).with(Line::Bot::V2::Webhook::UnfollowEvent).and_return(false)
      allow(event).to receive(:is_a?).with(Line::Bot::V2::Webhook::PostbackEvent).and_return(true)
      allow(event).to receive(:respond_to?).with(:postback).and_return(true)
      
      event
    end

    context "with valid signature" do
      before do
        allow_any_instance_of(LineBotService).to receive(:reply_message).and_return(double(code: '200'))
        allow_any_instance_of(LineBotService).to receive(:create_text_message).and_return(double('message'))
      end

      it "handles text message successfully" do
        mock_event = create_v2_text_message_event
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end

      it "handles recipe command via text message" do
        mock_event = create_v2_text_message_event("レシピ教えて")
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "handles ingredients command via text message" do
        mock_event = create_v2_text_message_event("食材リスト")
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "handles shopping command via text message" do
        mock_event = create_v2_text_message_event("買い物リスト")
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "handles unknown command via text message" do
        mock_event = create_v2_text_message_event("ランダムなメッセージ")
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "handles image message successfully" do
        mock_event = create_v2_image_message_event
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: image_message_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end

      it "handles follow event successfully" do
        mock_event = create_v2_follow_event
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: follow_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end

      it "handles postback event successfully" do
        mock_event = create_v2_postback_event
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: postback_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end

      it "handles recipe postback event" do
        mock_event = create_v2_postback_event("recipe_request")
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: postback_event, headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "handles ingredients postback event" do
        mock_event = create_v2_postback_event("ingredients_list")
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: postback_event, headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "handles shopping postback event" do
        mock_event = create_v2_postback_event("shopping_list")
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: postback_event, headers: headers

        expect(response).to have_http_status(:ok)
      end

      describe 'shopping list postback events' do
        let(:user) { create(:user) }
        let(:line_account) { create(:line_account, user: user, line_user_id: 'test_user_id') }
        let(:shopping_list) { create(:shopping_list, user: user, status: :pending) }
        let(:ingredient) { create(:ingredient, name: '玉ねぎ') }
        let(:shopping_list_item) { create(:shopping_list_item, shopping_list: shopping_list, ingredient: ingredient, is_checked: false) }

        before do
          line_account
          shopping_list_item
          allow_any_instance_of(LineBotService).to receive(:reply_message).and_return(double(code: '200'))
          allow_any_instance_of(LineBotService).to receive(:create_text_message).and_return(double('message'))
          allow_any_instance_of(LineBotService).to receive(:create_flex_message).and_return(double('message'))
          allow_any_instance_of(LineBotService).to receive(:generate_liff_url).and_return('https://liff.line.me/test')
        end

        it "handles check_item postback event" do
          mock_event = create_v2_postback_event("check_item:#{shopping_list.id}:#{shopping_list_item.id}")
          allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

          expect {
            post '/api/v1/line/webhook', params: postback_event, headers: headers
          }.to change { shopping_list_item.reload.is_checked }.from(false).to(true)

          expect(response).to have_http_status(:ok)
        end

        it "handles complete_list postback event" do
          mock_event = create_v2_postback_event("complete_list:#{shopping_list.id}")
          allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

          expect {
            post '/api/v1/line/webhook', params: postback_event, headers: headers
          }.to change { shopping_list.reload.status }.from('pending').to('completed')
          .and change { shopping_list_item.reload.is_checked }.from(false).to(true)
          .and change { shopping_list_item.reload.checked_at }.from(nil).to(be_present)

          expect(response).to have_http_status(:ok)
        end

        it "handles unauthorized shopping list access" do
          other_user = create(:user)
          other_shopping_list = create(:shopping_list, user: other_user)
          
          mock_event = create_v2_postback_event("check_item:#{other_shopping_list.id}:999")
          allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

          post '/api/v1/line/webhook', params: postback_event, headers: headers

          expect(response).to have_http_status(:ok)
        end
      end

      it "handles sticker message successfully" do
        mock_event = create_v2_sticker_message_event
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: sticker_message_event, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end

      it "handles unfollow event successfully" do
        mock_event = create_v2_unfollow_event
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2).and_return([mock_event])

        post '/api/v1/line/webhook', params: unfollow_event, headers: headers

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
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2)
          .and_raise(Line::Bot::V2::WebhookParser::InvalidSignatureError.new('Invalid signature'))
      end

      it "returns unauthorized for invalid signature" do
        post '/api/v1/line/webhook', params: text_message_event, headers: headers_with_invalid_signature

        expect(response).to have_http_status(:unauthorized)
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

    context "when general error occurs" do
      before do
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2)
          .and_raise(StandardError.new('General Error'))
      end

      it "returns internal server error" do
        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Internal server error')
      end
    end

    context "when webhook parsing fails" do
      before do
        allow_any_instance_of(LineBotService).to receive(:parse_events_v2)
          .and_raise(ArgumentError.new('Invalid JSON'))
      end

      it "returns internal server error for parsing errors" do
        post '/api/v1/line/webhook', params: text_message_event, headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Internal server error')
      end
    end
  end
end