require "rails_helper"

RSpec.describe "Api::V1::Users::Profiles", type: :request do
  let(:user) { create(:user, :confirmed) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/users/profile" do
    it "認証なしで401を返す" do
      get "/api/v1/users/profile", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "認証済みユーザーのプロフィールを返す" do
      headers = auth_header_for(user)
      get "/api/v1/users/profile", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq(user.name)
      expect(body["email"]).to eq(user.email)
      expect(body["provider"]).to eq(user.provider)
    end
  end

  describe "PATCH /api/v1/users/profile" do
    let(:valid_params) { { profile: { name: "新しい名前" } } }

    it "認証なしで401を返す" do
      patch "/api/v1/users/profile", params: valid_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "有効なパラメータでプロフィールを更新する" do
      headers = auth_header_for(user)
      patch "/api/v1/users/profile", params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("プロフィールを更新しました")
      user.reload
      expect(user.name).to eq("新しい名前")
    end

    it "nameが空の場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = { profile: { name: "" } }
      patch "/api/v1/users/profile", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("name")
    end

    it "nameが長すぎる場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = { profile: { name: "a" * 51 } }
      patch "/api/v1/users/profile", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("name")
    end
  end
end
