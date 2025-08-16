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
        expect(json['status']['message']).to eq('ログインしました。')
        expect(json['data']['email']).to eq(user.email)
      end

      it "JWTトークンがAuthorizationヘッダーに含まれる" do
        post "/api/v1/auth/login", params: valid_credentials, as: :json
        
        expect(response).to have_http_status(:ok)
        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to match(/^Bearer /)
      end
    end

    context "未確認ユーザーがログインを試みる場合（CONFIRMABLE_ENABLED=false）" do
      it "ログインに成功する（200）" do
        credentials = {
          user: {
            email: unconfirmed_user.email,
            password: "password123"
          }
        }
        
        post "/api/v1/auth/login", params: credentials, as: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']['message']).to eq('ログインしました。')
      end
    end

    context "誤ったパスワードでログインする場合" do
      it "ログインに失敗する（401）" do
        post "/api/v1/auth/login", params: invalid_credentials, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to include("メールアドレスまたはパスワードが正しくありません")
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
        expect(json['error']).to include("メールアドレスまたはパスワードが正しくありません")
      end
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let(:user) { create(:user, :confirmed) }

    context "認証済みユーザーがログアウトする場合" do
      it "ログアウトに成功し、トークンがブラックリストに追加される" do
        # まずログイン
        post "/api/v1/auth/login", params: {
          user: { email: user.email, password: "password123" }
        }, as: :json

        token = response.headers['Authorization']
        expect(token).to be_present

        # ログアウト
        delete "/api/v1/auth/logout", headers: { 'Authorization' => token }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('ログアウトしました。')

        # トークンがブラックリストに追加されていることを確認
        jti = JWT.decode(token.split(' ').last, ENV['DEVISE_JWT_SECRET_KEY'], false).first['jti']
        expect(JwtDenylist.exists?(jti: jti)).to be true
      end
    end

    context "トークンなしでログアウトを試みる場合" do
      it "エラーを返す（401）" do
        delete "/api/v1/auth/logout", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end