require 'rails_helper'

RSpec.describe 'Api::V1::Auth::LineToken', type: :request do
  let(:code) { 'test-authorization-code' }
  let(:nonce) { 'test-nonce-123' }
  let(:redirect_uri) { 'http://localhost:3001/auth/line/callback' }
  let(:id_token) { 'mock-id-token' }
  let(:access_token) { 'mock-access-token' }

  let(:token_response) do
    {
      id_token: id_token,
      access_token: access_token,
      expires_in: 3600,
      refresh_token: 'mock-refresh-token'
    }
  end

  let(:line_user_info) do
    {
      sub: 'U1234567890abcdef',
      name: 'Test User',
      picture: 'https://example.com/picture.jpg'
    }
  end

  before do
    # Mock LineTokenExchangeService (クラスメソッドのモック)
    allow(LineTokenExchangeService).to receive(:exchange_code_for_token)
      .and_return(token_response)

    # Mock LineAuthService
    allow(LineAuthService).to receive(:authenticate_with_id_token).and_call_original

    # Mock NonceStore and JwtVerifier
    allow(NonceStore).to receive(:verify_and_consume).and_return(true)
    allow(JwtVerifier).to receive(:verify_id_token).and_return(line_user_info)
  end

  describe 'POST /api/v1/auth/line/exchange' do
    let(:valid_params) do
      {
        code: code,
        nonce: nonce,
        redirect_uri: redirect_uri
      }
    end

    context '正常なパラメータの場合' do
      it '認証に成功しJWTトークンを返すこと' do
        post '/api/v1/auth/line/exchange', params: valid_params

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('token')
        expect(json_response).to have_key('user')
        expect(json_response).to have_key('lineAccount')

        user_data = json_response['user']
        expect(user_data['name']).to eq('Test User')
        expect(user_data['provider']).to eq('line')

        line_account_data = json_response['lineAccount']
        expect(line_account_data['lineUserId']).to eq('U1234567890abcdef')
        expect(line_account_data['displayName']).to eq('Test User')
      end

      it 'ユーザーとLINEアカウントが作成されること' do
        expect {
          post '/api/v1/auth/line/exchange', params: valid_params
        }.to change(User, :count).by(1)
         .and change(LineAccount, :count).by(1)
      end
    end

    context 'codeが不足している場合' do
      let(:invalid_params) { { nonce: nonce, redirect_uri: redirect_uri } }

      it 'bad requestエラーを返すこと' do
        post '/api/v1/auth/line/exchange', params: invalid_params

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('invalid_request')
        expect(json_response['error']['message']).to include('code, nonce, redirect_uriが必要です')
      end
    end

    context 'nonceが不足している場合' do
      let(:invalid_params) { { code: code, redirect_uri: redirect_uri } }

      it 'bad requestエラーを返すこと' do
        post '/api/v1/auth/line/exchange', params: invalid_params

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('invalid_request')
      end
    end

    context 'redirect_uriが不足している場合' do
      let(:invalid_params) { { code: code, nonce: nonce } }

      it 'bad requestエラーを返すこと' do
        post '/api/v1/auth/line/exchange', params: invalid_params

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('invalid_request')
      end
    end

    context 'トークン交換に失敗する場合' do
      before do
        # クラスメソッドのモックを上書き
        allow(LineTokenExchangeService).to receive(:exchange_code_for_token)
          .and_raise(LineTokenExchangeService::ExchangeError, 'Token exchange failed')
      end

      it 'unauthorizedエラーを返すこと' do
        post '/api/v1/auth/line/exchange', params: valid_params

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('token_exchange_failed')
        expect(json_response['error']['message']).to eq('Token exchange failed')
      end
    end

    context '認証に失敗する場合' do
      before do
        allow(LineAuthService)
          .to receive(:authenticate_with_id_token)
          .and_raise(LineAuthService::AuthenticationError, 'Invalid nonce')
      end

      it 'unauthorizedエラーを返すこと' do
        post '/api/v1/auth/line/exchange', params: valid_params

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('invalid_token')
        expect(json_response['error']['message']).to eq('Invalid nonce')
      end
    end

    context 'ノンス検証に失敗する場合' do
      before do
        allow(LineAuthService)
          .to receive(:authenticate_with_id_token)
          .and_raise(LineAuthService::AuthenticationError, 'Nonce mismatch')
      end

      it 'nonce_mismatchエラーを返すこと' do
        post '/api/v1/auth/line/exchange', params: valid_params

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('nonce_mismatch')
      end
    end

    context '既存のLINEアカウントでログインする場合' do
      let!(:existing_user) { create(:user, provider: 'line') }
      let!(:existing_line_account) do
        create(:line_account,
               line_user_id: 'U1234567890abcdef',
               user: existing_user,
               linked_at: 1.day.ago)
      end

      it '既存ユーザーでログインできること' do
        expect {
          post '/api/v1/auth/line/exchange', params: valid_params
        }.to change(User, :count).by(0)
         .and change(LineAccount, :count).by(0)

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['user']['id']).to eq(existing_user.id)
      end
    end
  end

  describe "POST /api/v1/auth/line/exchange_link" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:valid_code) { "valid_authorization_code" }
    let(:link_nonce) { "test-link-nonce-456" }
    let(:line_user_id) { "U987654321" }
    let(:auth_headers) do
      # JWTトークンを生成
      token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
      { "Authorization" => "Bearer #{token}" }
    end

    before do
      # 全テストケースで共通: LineTokenExchangeServiceをスタブ化
      allow(LineTokenExchangeService).to receive(:exchange_code_for_token)
        .with(code: valid_code, redirect_uri: redirect_uri)
        .and_return({
          id_token: generate_mock_id_token(line_user_id: line_user_id),
          access_token: "mock_access_token"
        })

      # 全テストケースで共通: JwtVerifierをスタブ化
      allow(JwtVerifier).to receive(:verify_id_token)
        .and_return({
          sub: line_user_id,
          name: "Link Test User",
          picture: "https://example.com/link_picture.jpg"
        })

      # NonceStoreの検証処理をスタブ化（デフォルトは成功）
      allow(NonceStore).to receive(:verify_and_consume)
        .with(link_nonce)
        .and_return(true)
    end

    context "正常ケース" do
      it "LINEアカウントを連携し、新しいJWTを返す" do
        post "/api/v1/auth/line/exchange_link", params: {
          code: valid_code,
          nonce: link_nonce,
          redirect_uri: redirect_uri
        }, headers: auth_headers

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["token"]).to be_present
        expect(json["user"]["id"]).to eq(user.id)
        expect(json["lineAccount"]).to be_present
        expect(json["lineAccount"]["lineUserId"]).to eq(line_user_id)
        expect(json["message"]).to eq("LINE account linked successfully")

        # データベースの確認
        user.reload
        expect(user.line_account).to be_present
        expect(user.line_account.line_user_id).to eq(line_user_id)
      end
    end

    context "エラーケース: 既に他ユーザーに連携済み" do
      let!(:existing_line_account) do
        create(:line_account, user: other_user, line_user_id: line_user_id)
      end

      it "409 Conflictを返す" do
        post "/api/v1/auth/line/exchange_link", params: {
          code: valid_code,
          nonce: link_nonce,
          redirect_uri: redirect_uri
        }, headers: auth_headers

        expect(response).to have_http_status(:conflict)

        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("already_linked")
        expect(json["error"]["message"]).to include("他のユーザー")

        # current_userにはLINEアカウントが紐付いていないことを確認
        user.reload
        expect(user.line_account).to be_nil
      end
    end

    context "エラーケース: nonce不一致" do
      it "401 Unauthorizedを返す" do
        # nonce検証のみ失敗させる
        allow(NonceStore).to receive(:verify_and_consume)
          .with("invalid-nonce")
          .and_raise(NonceStore::NonceNotFoundError, "Nonce not found or expired")

        post "/api/v1/auth/line/exchange_link", params: {
          code: valid_code,
          nonce: "invalid-nonce",
          redirect_uri: redirect_uri
        }, headers: auth_headers

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("nonce_mismatch")
      end
    end

    context "エラーケース: パラメータ不足" do
      it "code欠落時に400 Bad Requestを返す" do
        post "/api/v1/auth/line/exchange_link", params: {
          nonce: link_nonce,
          redirect_uri: redirect_uri
        }, headers: auth_headers

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("invalid_request")
        expect(json["error"]["message"]).to include("code")
      end

      it "nonce欠落時に400 Bad Requestを返す" do
        post "/api/v1/auth/line/exchange_link", params: {
          code: valid_code,
          redirect_uri: redirect_uri
        }, headers: auth_headers

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("invalid_request")
        expect(json["error"]["message"]).to include("nonce")
      end

      it "redirect_uri欠落時に400 Bad Requestを返す" do
        post "/api/v1/auth/line/exchange_link", params: {
          code: valid_code,
          nonce: link_nonce
        }, headers: auth_headers

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("invalid_request")
        expect(json["error"]["message"]).to include("redirect_uri")
      end
    end

    context "エラーケース: 未認証" do
      it "401 Unauthorizedを返す" do
        # Authorizationヘッダーなしでリクエスト
        post "/api/v1/auth/line/exchange_link", params: {
          code: valid_code,
          nonce: link_nonce,
          redirect_uri: redirect_uri
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "エラーケース: トークン交換失敗" do
      it "401 Unauthorizedを返す" do
        # beforeブロックのスタブを上書き
        allow(LineTokenExchangeService).to receive(:exchange_code_for_token)
          .and_raise(LineTokenExchangeService::ExchangeError, "Failed to exchange authorization code")

        post "/api/v1/auth/line/exchange_link", params: {
          code: valid_code,
          nonce: link_nonce,
          redirect_uri: redirect_uri
        }, headers: auth_headers

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("token_exchange_failed")
      end
    end

    context "エラーケース: IDトークン検証失敗" do
      it "401 Unauthorizedを返す" do
        # JwtVerifierのスタブを上書き
        allow(JwtVerifier).to receive(:verify_id_token)
          .and_raise(JwtVerifier::VerificationError, "Invalid token signature")

        post "/api/v1/auth/line/exchange_link", params: {
          code: valid_code,
          nonce: link_nonce,
          redirect_uri: redirect_uri
        }, headers: auth_headers

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("invalid_token")
      end
    end
  end

  # ヘルパーメソッド
  private

  def generate_mock_id_token(line_user_id:)
    # 注意: このメソッドは固定文字列を返します。
    # JwtVerifier.verify_id_tokenを完全にモックしている前提で機能します。
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock_payload_#{line_user_id}.mock_signature"
  end
end
