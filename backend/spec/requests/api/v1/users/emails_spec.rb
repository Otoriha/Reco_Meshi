require "rails_helper"

RSpec.describe "Api::V1::Users::Emails", type: :request do
  let(:user) { create(:user, :confirmed, password: "password123", password_confirmation: "password123") }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "POST /api/v1/users/change_email" do
    let(:valid_params) do
      {
        email_change: {
          email: "newemail@example.com",
          current_password: "password123"
        }
      }
    end

    it "認証なしで401を返す" do
      post "/api/v1/users/change_email", params: valid_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "有効なパラメータでメールアドレスを変更する" do
      headers = auth_header_for(user)
      post "/api/v1/users/change_email", params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("メールアドレスを変更しました。確認メールを送信しました")
      user.reload
      expect(user.email).to eq("newemail@example.com")
    end

    it "current_passwordが不一致の場合401を返す" do
      headers = auth_header_for(user)
      invalid_params = {
        email_change: {
          email: "newemail@example.com",
          current_password: "wrongpassword"
        }
      }
      post "/api/v1/users/change_email", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("パスワードが正しくありません")
    end

    it "emailが重複する場合422を返す" do
      existing_user = create(:user, :confirmed, email: "existing@example.com")
      headers = auth_header_for(user)
      invalid_params = {
        email_change: {
          email: "existing@example.com",
          current_password: "password123"
        }
      }
      post "/api/v1/users/change_email", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("email")
    end

    it "emailの形式が不正な場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = {
        email_change: {
          email: "invalid-email",
          current_password: "password123"
        }
      }
      post "/api/v1/users/change_email", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("email")
    end
  end
end
