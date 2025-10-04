require "rails_helper"

RSpec.describe "Api::V1::Users::Settings", type: :request do
  let(:user) { create(:user, :confirmed) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/users/settings" do
    it "認証なしで401を返す" do
      get "/api/v1/users/settings", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "認証済みユーザーの設定を返す" do
      headers = auth_header_for(user)
      get "/api/v1/users/settings", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to have_key("default_servings")
      expect(body).to have_key("recipe_difficulty")
      expect(body).to have_key("cooking_time")
      expect(body).to have_key("shopping_frequency")
      expect(body["default_servings"]).to eq(2)
      expect(body["recipe_difficulty"]).to eq("medium")
    end
  end

  describe "PATCH /api/v1/users/settings" do
    let(:valid_params) do
      {
        settings: {
          default_servings: 4,
          recipe_difficulty: "easy",
          cooking_time: 60,
          shopping_frequency: "週に1回"
        }
      }
    end

    it "認証なしで401を返す" do
      patch "/api/v1/users/settings", params: valid_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "有効なパラメータで設定を更新する" do
      headers = auth_header_for(user)
      patch "/api/v1/users/settings", params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("設定を保存しました")
      user.reload
      expect(user.setting.default_servings).to eq(4)
      expect(user.setting.recipe_difficulty).to eq("easy")
      expect(user.setting.cooking_time).to eq(60)
      expect(user.setting.shopping_frequency).to eq("週に1回")
    end

    it "recipe_difficultyが不正な値の場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = { settings: { recipe_difficulty: "invalid" } }
      patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("recipe_difficulty")
    end

    it "default_servingsが範囲外（0）の場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = { settings: { default_servings: 0 } }
      patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("default_servings")
    end

    it "default_servingsが範囲外（11）の場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = { settings: { default_servings: 11 } }
      patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("default_servings")
    end

    it "cooking_timeが不正な値（45）の場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = { settings: { cooking_time: 45 } }
      patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("cooking_time")
    end

    it "shopping_frequencyが不正な値の場合422を返す" do
      headers = auth_header_for(user)
      invalid_params = { settings: { shopping_frequency: "毎週" } }
      patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("shopping_frequency")
    end
  end
end
