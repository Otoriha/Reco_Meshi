require 'rails_helper'

RSpec.describe 'Api::V1::Auth::Confirmations', type: :request do
  # These tests require Confirmable module to be enabled
  before(:all) { skip('Confirmable is disabled') if ENV['CONFIRMABLE_ENABLED'] != 'true' }

  describe 'GET /api/v1/auth/confirmation' do
    let(:user) { create(:user, confirmed_at: nil) }

    before do
      user.send_confirmation_instructions
      @confirmation_token = user.confirmation_token
    end

    context 'with valid token' do
      it 'confirms user email successfully' do
        get '/api/v1/auth/confirmation', params: {
          confirmation_token: @confirmation_token
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to include('確認しました')

        user.reload
        expect(user.confirmed_at).not_to be_nil
      end
    end

    context 'with invalid token' do
      it 'returns unprocessable entity' do
        get '/api/v1/auth/confirmation', params: {
          confirmation_token: 'invalid_token'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to be_present
      end
    end

    context 'when already confirmed' do
      let(:confirmed_user) { create(:user, confirmed_at: Time.current) }

      before do
        confirmed_user.send_confirmation_instructions
        @confirmed_token = confirmed_user.confirmation_token
      end

      it 'returns error' do
        get '/api/v1/auth/confirmation', params: {
          confirmation_token: @confirmed_token
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /api/v1/auth/confirmation' do
    let(:user) { create(:user, confirmed_at: nil) }

    context 'when email exists' do
      it 'resends confirmation email' do
        expect {
          post '/api/v1/auth/confirmation', params: {
            user: { email: user.email }
          }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to include('再送信')
      end
    end

    context 'when email does not exist' do
      it 'returns success (paranoid mode)' do
        expect {
          post '/api/v1/auth/confirmation', params: {
            user: { email: 'nonexistent@example.com' }
          }
        }.not_to change { ActionMailer::Base.deliveries.count }

        # paranoid=true: Same success response regardless of email existence
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to include('再送信')
      end
    end

    context 'when email format is invalid' do
      it 'returns success (paranoid mode - same as non-existent email)' do
        # Devise の paranoid mode により、無効なフォーマットでも成功を返す
        post '/api/v1/auth/confirmation', params: {
          user: { email: 'invalid-email' }
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to include('再送信')
      end
    end
  end
end
