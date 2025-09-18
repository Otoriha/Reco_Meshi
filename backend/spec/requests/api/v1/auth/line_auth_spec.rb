require 'rails_helper'

RSpec.describe 'Api::V1::Auth::LineAuth', type: :request do
  let(:id_token) { 'mock-id-token' }
  let(:nonce) { 'test-nonce-123' }
  let(:line_user_info) do
    {
      sub: 'U1234567890abcdef',
      name: 'Test User',
      picture: 'https://example.com/picture.jpg'
    }
  end

  before do
    # Mock authentication services
    allow(NonceStore).to receive(:verify_and_consume).and_return(true)
    allow(JwtVerifier).to receive(:verify_id_token).and_return(line_user_info)
    allow(LineAuthService).to receive(:authenticate_with_id_token).and_call_original
    allow(LineAuthService).to receive(:link_existing_user).and_call_original
  end

  describe 'POST /api/v1/auth/line_login' do
    let(:valid_params) { { idToken: id_token, nonce: nonce } }

    context 'with valid parameters' do
      it 'authenticates user and returns JWT token' do
        post '/api/v1/auth/line_login', params: valid_params

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
    end

    context 'with missing idToken' do
      let(:invalid_params) { { nonce: nonce } }

      it 'returns bad request error' do
        post '/api/v1/auth/line_login', params: invalid_params

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('invalid_request')
        expect(json_response['error']['message']).to include('idTokenとnonceが必要です')
      end
    end

    context 'with missing nonce' do
      let(:invalid_params) { { idToken: id_token } }

      it 'returns bad request error' do
        post '/api/v1/auth/line_login', params: invalid_params

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('invalid_request')
      end
    end

    context 'when authentication fails' do
      before do
        allow(LineAuthService).to receive(:authenticate_with_id_token)
          .and_raise(LineAuthService::AuthenticationError, 'Invalid token')
      end

      it 'returns unauthorized error' do
        post '/api/v1/auth/line_login', params: valid_params

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('invalid_token')
        expect(json_response['error']['message']).to eq('Invalid token')
      end
    end

    context 'when nonce verification fails' do
      before do
        allow(LineAuthService).to receive(:authenticate_with_id_token)
          .and_raise(LineAuthService::AuthenticationError, 'Nonce mismatch')
      end

      it 'returns nonce mismatch error' do
        post '/api/v1/auth/line_login', params: valid_params

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('nonce_mismatch')
      end
    end
  end

  describe 'POST /api/v1/auth/line_link' do
    let(:user) { create(:user) }
    let(:valid_params) { { idToken: id_token, nonce: nonce } }
    let(:auth_headers) { user.create_new_auth_token }

    before do
      # Mock JWT authentication
      allow_any_instance_of(Api::V1::Auth::LineAuthController)
        .to receive(:authenticate_user!).and_return(true)
      allow_any_instance_of(Api::V1::Auth::LineAuthController)
        .to receive(:current_user).and_return(user)
    end

    context 'with valid parameters and authenticated user' do
      it 'links LINE account to existing user' do
        post '/api/v1/auth/line_link', params: valid_params

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('LINE account linked successfully')
        expect(json_response).to have_key('lineAccount')

        line_account_data = json_response['lineAccount']
        expect(line_account_data['lineUserId']).to eq('U1234567890abcdef')
        expect(line_account_data['linked']).to be true
      end
    end

    context 'when LINE account is already linked to another user' do
      before do
        allow(LineAuthService).to receive(:link_existing_user)
          .and_raise(LineAuthService::AuthenticationError, 'LINE account is already linked to another user')
      end

      it 'returns conflict error' do
        post '/api/v1/auth/line_link', params: valid_params

        expect(response).to have_http_status(:conflict)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('already_linked')
        expect(json_response['error']['message']).to include('既に他のユーザーに連携されています')
      end
    end

    context 'without authentication' do
      before do
        allow_any_instance_of(Api::V1::Auth::LineAuthController)
          .to receive(:authenticate_user!).and_raise(StandardError, 'Unauthorized')
      end

      it 'returns unauthorized error' do
        expect {
          post '/api/v1/auth/line_link', params: valid_params
        }.to raise_error(StandardError, 'Unauthorized')
      end
    end
  end

  describe 'GET /api/v1/auth/line_profile' do
    let(:user) { create(:user) }
    let!(:line_account) { create(:line_account, :linked, user: user) }

    before do
      # Mock JWT authentication
      allow_any_instance_of(Api::V1::Auth::LineAuthController)
        .to receive(:authenticate_user!).and_return(true)
      allow_any_instance_of(Api::V1::Auth::LineAuthController)
        .to receive(:current_user).and_return(user)
    end

    context 'with linked LINE account' do
      it 'returns user and LINE account information' do
        get '/api/v1/auth/line_profile'

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('user')
        expect(json_response).to have_key('lineAccount')

        user_data = json_response['user']
        expect(user_data['id']).to eq(user.id)

        line_account_data = json_response['lineAccount']
        expect(line_account_data['lineUserId']).to eq(line_account.line_user_id)
        expect(line_account_data['linked']).to be true
      end
    end

    context 'without linked LINE account' do
      let(:user_without_line) { create(:user) }

      before do
        allow_any_instance_of(Api::V1::Auth::LineAuthController)
          .to receive(:current_user).and_return(user_without_line)
      end

      it 'returns not found error' do
        get '/api/v1/auth/line_profile'

        expect(response).to have_http_status(:not_found)

        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('line_account_not_found')
        expect(json_response['error']['message']).to include('LINEアカウントが連携されていません')
      end
    end
  end

  describe 'POST /api/v1/auth/generate_nonce' do
    before do
      allow(NonceStore).to receive(:generate_and_store).and_return('generated-nonce-123')
    end

    it 'generates and returns a nonce' do
      post '/api/v1/auth/generate_nonce'

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['nonce']).to eq('generated-nonce-123')
    end
  end
end
