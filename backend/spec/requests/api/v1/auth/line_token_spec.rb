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
    # Mock LineTokenExchangeService
    allow_any_instance_of(LineTokenExchangeService)
      .to receive(:exchange_code_for_token)
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
        allow_any_instance_of(LineTokenExchangeService)
          .to receive(:exchange_code_for_token)
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
end
