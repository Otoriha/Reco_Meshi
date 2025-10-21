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

  describe "通知設定の取得・更新" do
    describe "GET /api/v1/users/settings（通知設定を含む）" do
      it "通知設定を含む全設定を返す" do
        headers = auth_header_for(user)
        get "/api/v1/users/settings", headers: headers, as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body).to have_key("inventory_reminder_enabled")
        expect(body).to have_key("inventory_reminder_time")
        expect(body["inventory_reminder_enabled"]).to eq(false)
        expect(body["inventory_reminder_time"]).to match(/^\d{2}:\d{2}$/)  # HH:MM形式
        expect(body["inventory_reminder_time"]).to eq('09:00')  # デフォルト値
      end
    end

    describe "PATCH /api/v1/users/settings（通知設定の更新）" do
      context "有効な時刻で更新" do
        it "有効な時刻（09:00形式）で更新できる" do
          headers = auth_header_for(user)
          params = { settings: { inventory_reminder_enabled: true, inventory_reminder_time: "10:30" } }
          patch "/api/v1/users/settings", params: params, headers: headers, as: :json
          expect(response).to have_http_status(:ok)
          user.reload
          expect(user.setting.inventory_reminder_enabled).to eq(true)
          expect(user.setting.inventory_reminder_time.strftime('%H:%M')).to eq('10:30')
        end

        it "通知設定のみを更新できる（部分更新）" do
          headers = auth_header_for(user)
          original_servings = user.setting.default_servings
          params = { settings: { inventory_reminder_enabled: true } }
          patch "/api/v1/users/settings", params: params, headers: headers, as: :json
          expect(response).to have_http_status(:ok)
          user.reload
          expect(user.setting.inventory_reminder_enabled).to eq(true)
          expect(user.setting.default_servings).to eq(original_servings)  # 変更されない
        end

        it "既存パラメータのみの更新も継続可能（互換性）" do
          headers = auth_header_for(user)
          params = { settings: { default_servings: 3 } }
          patch "/api/v1/users/settings", params: params, headers: headers, as: :json
          expect(response).to have_http_status(:ok)
          user.reload
          expect(user.setting.default_servings).to eq(3)
          expect(user.setting.inventory_reminder_enabled).to eq(false)  # 変更されない
        end
      end

      context "時刻フォーマットの厳密な検証" do
        it "不正な時刻形式（25:00）で422エラーを返す" do
          headers = auth_header_for(user)
          invalid_params = { settings: { inventory_reminder_time: "25:00" } }
          patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body["error"]["code"]).to eq("INVALID_TIME_FORMAT")
        end

        it "1桁時刻（9:00）で422エラーを返す" do
          headers = auth_header_for(user)
          invalid_params = { settings: { inventory_reminder_time: "9:00" } }
          patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body["error"]["code"]).to eq("INVALID_TIME_FORMAT")
          expect(body["error"]["message"]).to include("HH:MM形式")
        end

        it "1桁分（09:0）で422エラーを返す" do
          headers = auth_header_for(user)
          invalid_params = { settings: { inventory_reminder_time: "09:0" } }
          patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body["error"]["code"]).to eq("INVALID_TIME_FORMAT")
        end

        it "不正な文字列（abc）で422エラーを返す" do
          headers = auth_header_for(user)
          invalid_params = { settings: { inventory_reminder_time: "abc" } }
          patch "/api/v1/users/settings", params: invalid_params, headers: headers, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body["error"]["code"]).to eq("INVALID_TIME_FORMAT")
        end

        it "境界値（00:00）は有効" do
          headers = auth_header_for(user)
          params = { settings: { inventory_reminder_time: "00:00" } }
          patch "/api/v1/users/settings", params: params, headers: headers, as: :json
          expect(response).to have_http_status(:ok)
          user.reload
          expect(user.setting.inventory_reminder_time.strftime('%H:%M')).to eq('00:00')
        end

        it "境界値（23:59）は有効" do
          headers = auth_header_for(user)
          params = { settings: { inventory_reminder_time: "23:59" } }
          patch "/api/v1/users/settings", params: params, headers: headers, as: :json
          expect(response).to have_http_status(:ok)
          user.reload
          expect(user.setting.inventory_reminder_time.strftime('%H:%M')).to eq('23:59')
        end
      end
    end
  end
end
