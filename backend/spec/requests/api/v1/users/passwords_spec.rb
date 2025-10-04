require "rails_helper"

RSpec.describe "Api::V1::Users::Passwords", type: :request do
  let(:user) { create(:user, :confirmed, password: "password123", password_confirmation: "password123") }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "POST /api/v1/users/change_password" do
    let(:valid_params) do
      {
        password: {
          current_password: "password123",
          new_password: "newpassword123",
          new_password_confirmation: "newpassword123"
        }
      }
    end

    it "認証なしで401を返す" do
      post "/api/v1/users/change_password", params: valid_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "有効なパラメータでパスワードを変更する" do
      headers = auth_header_for(user)
      post "/api/v1/users/change_password", params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("パスワードを変更しました。セキュリティのため再ログインしてください")
      user.reload
      expect(user.valid_password?("newpassword123")).to be true
    end

    it "current_passwordが不一致の場合401を返す" do
      headers = auth_header_for(user)
      invalid_params = {
        password: {
          current_password: "wrongpassword",
          new_password: "newpassword123",
          new_password_confirmation: "newpassword123"
        }
      }
      post "/api/v1/users/change_password", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("現在のパスワードが正しくありません")
    end

    it "new_passwordが短すぎる場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = {
        password: {
          current_password: "password123",
          new_password: "short",
          new_password_confirmation: "short"
        }
      }
      post "/api/v1/users/change_password", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("password")
    end

    it "new_password_confirmationが不一致の場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = {
        password: {
          current_password: "password123",
          new_password: "newpassword123",
          new_password_confirmation: "differentpassword"
        }
      }
      post "/api/v1/users/change_password", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("password_confirmation")
    end
  end
end
