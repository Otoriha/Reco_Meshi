require 'rails_helper'

RSpec.describe 'Api::V1::Auth::Passwords', type: :request do
  describe 'POST /api/v1/auth/password' do
    let(:user) { create(:user, confirmed_at: Time.current) }

    context 'when email exists' do
      it 'sends password reset email' do
        expect {
          post '/api/v1/auth/password', params: {
            user: { email: user.email }
          }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to include('パスワードリセットメール')
      end
    end

    context 'when email does not exist' do
      it 'returns success (paranoid mode)' do
        expect {
          post '/api/v1/auth/password', params: {
            user: { email: 'nonexistent@example.com' }
          }
        }.not_to change { ActionMailer::Base.deliveries.count }

        # paranoid=true: Same success response regardless of email existence
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to include('パスワードリセットメール')
      end
    end

    context 'when email format is invalid' do
      it 'returns unprocessable entity' do
        post '/api/v1/auth/password', params: {
          user: { email: 'invalid-email' }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to be_present
      end
    end
  end

  describe 'PUT /api/v1/auth/password' do
    let(:user) { create(:user, confirmed_at: Time.current) }
    let(:new_password) { 'NewPassword123!' }

    before do
      user.send_reset_password_instructions
      @reset_token = user.reset_password_token
    end

    context 'with valid token and password' do
      it 'resets password successfully' do
        put '/api/v1/auth/password', params: {
          user: {
            password: new_password,
            password_confirmation: new_password,
            reset_password_token: @reset_token
          }
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to include('パスワードを変更しました')

        user.reload
        expect(user.valid_password?(new_password)).to be true
      end
    end

    context 'with invalid token' do
      it 'returns unprocessable entity' do
        put '/api/v1/auth/password', params: {
          user: {
            password: new_password,
            password_confirmation: new_password,
            reset_password_token: 'invalid_token'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to be_present
      end
    end

    context 'when passwords do not match' do
      it 'returns unprocessable entity' do
        put '/api/v1/auth/password', params: {
          user: {
            password: new_password,
            password_confirmation: 'DifferentPassword123!',
            reset_password_token: @reset_token
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to be_present
      end
    end
  end
end
