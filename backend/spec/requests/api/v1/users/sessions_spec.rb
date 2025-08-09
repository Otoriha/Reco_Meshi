require 'rails_helper'

RSpec.describe "Api::V1::Users::Sessions", type: :request do
  describe "POST /api/v1/auth/login" do
    let(:user) { create(:user, :confirmed) }
    let(:unconfirmed_user) { create(:user) }

    let(:valid_credentials) do
      {
        user: {
          email: user.email,
          password: "password123"
        }
      }
    end

    let(:invalid_credentials) do
      {
        user: {
          email: user.email,
          password: "wrong_password"
        }
      }
    end

    context "確認済みユーザーが正しい認証情報でログインする場合" do
      it "ログインに成功する（200）" do
        post "/api/v1/auth/login", params: valid_credentials, as: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']['message']).to eq('Logged in successfully.')
        expect(json['data']['email']).to eq(user.email)
      end
    end

    context "未確認ユーザーがログインを試みる場合" do
      it "ログインに失敗する（401）" do
        credentials = {
          user: {
            email: unconfirmed_user.email,
            password: "password123"
          }
        }
        
        post "/api/v1/auth/login", params: credentials, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to include("You have to confirm your email address")
      end
    end

    context "誤ったパスワードでログインする場合" do
      it "ログインに失敗する（401）" do
        post "/api/v1/auth/login", params: invalid_credentials, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to include("Invalid Email or password")
      end
    end

    context "存在しないユーザーでログインする場合" do
      it "ログインに失敗する（401）" do
        credentials = {
          user: {
            email: "nonexistent@example.com",
            password: "password123"
          }
        }
        
        post "/api/v1/auth/login", params: credentials, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to include("Invalid Email or password")
      end
    end
  end
end