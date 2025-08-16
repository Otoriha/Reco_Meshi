require 'rails_helper'

RSpec.describe "Api::V1::Users::Registrations", type: :request do
  describe "POST /api/v1/auth/signup" do
    let(:valid_params) do
      {
        user: {
          name: "テストユーザー",
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    let(:invalid_params) do
      {
        user: {
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    context "正常なパラメータの場合" do
      it "新規ユーザーが作成される（200）" do
        expect {
          post "/api/v1/auth/signup", params: valid_params, as: :json
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']['message']).to eq('新規登録が完了しました。')
      end

      it "確認メールは送信されない（CONFIRMABLE_ENABLED=false）" do
        expect {
          post "/api/v1/auth/signup", params: valid_params, as: :json
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "新規登録時にJWTトークンが発行され、confirmed=trueが含まれる（CONFIRMABLE_ENABLED=false）" do
        post "/api/v1/auth/signup", params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        token = response.headers['Authorization']
        expect(token).to be_present
        expect(token).to match(/^Bearer /)

        payload = JWT.decode(token.split(' ').last, ENV['DEVISE_JWT_SECRET_KEY'], false).first
        expect(payload['email']).to eq('test@example.com')
        expect(payload['confirmed']).to eq(true) # CONFIRMABLE_ENABLED=false なので true
      end
    end

    context "nameが未入力の場合" do
      it "エラーが返される（422）" do
        post "/api/v1/auth/signup", params: invalid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['status']['message']).to include("Name can't be blank")
      end
    end

    context "重複したメールアドレスの場合" do
      before do
        create(:user, email: "test@example.com")
      end

      it "エラーが返される（422）" do
        post "/api/v1/auth/signup", params: valid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['status']['message']).to include("Email has already been taken")
      end
    end
  end

  # Environment-specific behavior tests
  describe "CONFIRMABLE_ENABLED environment variable behavior" do
    let(:valid_params) do
      {
        user: {
          name: "テストユーザー",
          email: "env_test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    context "when CONFIRMABLE_ENABLED=false" do
      around do |example|
        original_value = ENV['CONFIRMABLE_ENABLED']
        ENV['CONFIRMABLE_ENABLED'] = 'false'
        # Reload User class to apply new devise configuration
        Rails.application.reloader.reload!
        example.run
        ENV['CONFIRMABLE_ENABLED'] = original_value
        Rails.application.reloader.reload!
      end

      it "signup時にJWTトークンが発行され、confirmed=trueが含まれる" do
        post "/api/v1/auth/signup", params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        
        # Check response message
        json = JSON.parse(response.body)
        expect(json['status']['message']).to eq('新規登録が完了しました。')
        expect(json['data']).to be_present
        expect(json['data']['name']).to eq('テストユーザー')
        expect(json['data']['email']).to eq('env_test@example.com')

        # Check JWT token in Authorization header
        token = response.headers['Authorization']
        expect(token).to be_present
        expect(token).to match(/^Bearer /)

        # Decode and verify JWT payload
        payload = JWT.decode(token.split(' ').last, ENV['DEVISE_JWT_SECRET_KEY'], false).first
        expect(payload['email']).to eq('env_test@example.com')
        expect(payload['confirmed']).to eq(true) # Should be true when confirmable disabled
      end

      it "確認メールは送信されない" do
        expect {
          post "/api/v1/auth/signup", params: valid_params, as: :json
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "作成したユーザーでそのままログインできる" do
        # First, signup
        post "/api/v1/auth/signup", params: valid_params, as: :json
        expect(response).to have_http_status(:ok)

        # Then, try to login with the same credentials
        login_params = {
          user: {
            email: "env_test@example.com",
            password: "password123"
          }
        }

        post "/api/v1/auth/login", params: login_params, as: :json
        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['status']['message']).to eq('ログインしました。')
        expect(json['data']['email']).to eq('env_test@example.com')
      end
    end

    context "when CONFIRMABLE_ENABLED=true" do
      around do |example|
        original_value = ENV['CONFIRMABLE_ENABLED']
        ENV['CONFIRMABLE_ENABLED'] = 'true'
        # Reload User class to apply new devise configuration
        Rails.application.reloader.reload!
        example.run
        ENV['CONFIRMABLE_ENABLED'] = original_value
        Rails.application.reloader.reload!
      end

      it "signup時にJWTトークンが発行されず、確認メール送信メッセージが返る" do
        post "/api/v1/auth/signup", params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        
        # Check response message
        json = JSON.parse(response.body)
        expect(json['status']['message']).to eq('確認メールを送信しました。メールをご確認ください。')
        expect(json['data']).to be_nil # No user data returned

        # Check no JWT token in Authorization header
        token = response.headers['Authorization']
        expect(token).to be_blank
      end

      it "確認メールは送信されない（将来実装）" do
        expect {
          post "/api/v1/auth/signup", params: valid_params, as: :json
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "未確認ユーザーはログインできない（401）" do
        # First, signup
        post "/api/v1/auth/signup", params: valid_params, as: :json
        expect(response).to have_http_status(:ok)

        # Then, try to login without email confirmation
        login_params = {
          user: {
            email: "env_test@example.com",
            password: "password123"
          }
        }

        post "/api/v1/auth/login", params: login_params, as: :json
        expect(response).to have_http_status(:unauthorized)
        
        json = JSON.parse(response.body)
        expect(json['error']).to eq('メールアドレスの確認が必要です')
      end

      it "確認後のユーザーはログインできる" do
        # First, signup
        post "/api/v1/auth/signup", params: valid_params, as: :json
        expect(response).to have_http_status(:ok)

        # Manually confirm the user (simulating email confirmation)
        user = User.find_by(email: "env_test@example.com")
        user.update(confirmed_at: Time.current)

        # Then, try to login after confirmation
        login_params = {
          user: {
            email: "env_test@example.com",
            password: "password123"
          }
        }

        post "/api/v1/auth/login", params: login_params, as: :json
        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['status']['message']).to eq('ログインしました。')
        expect(json['data']['email']).to eq('env_test@example.com')
      end
    end
  end
end