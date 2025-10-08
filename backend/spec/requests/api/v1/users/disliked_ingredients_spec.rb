require "rails_helper"

RSpec.describe "Api::V1::Users::DislikedIngredients", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed, email: "other@example.com") }
  let(:ingredient) { create(:ingredient, name: "セロリ") }
  let(:cilantro_ingredient) { create(:ingredient, name: "パクチー") }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/users/disliked_ingredients" do
    let!(:disliked1) { create(:disliked_ingredient, user: user, ingredient: ingredient, priority: :low) }
    let!(:disliked2) { create(:disliked_ingredient, user: user, ingredient: cilantro_ingredient, priority: :high) }
    let!(:other_disliked) { create(:disliked_ingredient, user: other_user, ingredient: ingredient) }

    it "認証なしで401を返す" do
      get "/api/v1/users/disliked_ingredients", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "認証済みユーザーの苦手食材一覧を返す" do
      headers = auth_header_for(user)
      get "/api/v1/users/disliked_ingredients", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(2)

      # 最新順で返される
      expect(body.first["id"]).to eq(disliked2.id.to_s)
      expect(body.first["ingredient_id"]).to eq(cilantro_ingredient.id)
      expect(body.first["priority"]).to eq("high")
      expect(body.first["priority_label"]).to eq("高")
      expect(body.first["ingredient"]["name"]).to eq("パクチー")

      expect(body.last["id"]).to eq(disliked1.id.to_s)
      expect(body.last["ingredient_id"]).to eq(ingredient.id)
      expect(body.last["priority"]).to eq("low")
      expect(body.last["priority_label"]).to eq("低")
    end

    it "他のユーザーの苦手食材は返さない" do
      headers = auth_header_for(user)
      get "/api/v1/users/disliked_ingredients", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      user_ids = body.map { |item| item["user_id"] }.uniq
      expect(user_ids).to eq([ user.id ])
      expect(user_ids).not_to include(other_user.id)
    end
  end

  describe "POST /api/v1/users/disliked_ingredients" do
    let(:valid_params) do
      {
        disliked_ingredient: {
          ingredient_id: ingredient.id,
          priority: "medium",
          reason: "苦味が強くて食べられない"
        }
      }
    end

    it "認証なしで401を返す" do
      post "/api/v1/users/disliked_ingredients", params: valid_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "有効なパラメータで苦手食材を登録する" do
      headers = auth_header_for(user)

      expect {
        post "/api/v1/users/disliked_ingredients", params: valid_params, headers: headers, as: :json
      }.to change(DislikedIngredient, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["id"]).to be_present
      expect(body["user_id"]).to eq(user.id)
      expect(body["ingredient_id"]).to eq(ingredient.id)
      expect(body["priority"]).to eq("medium")
      expect(body["priority_label"]).to eq("中")
      expect(body["reason"]).to eq("苦味が強くて食べられない")
      expect(body["ingredient"]["name"]).to eq("セロリ")
    end

    it "reasonなしでも登録できる" do
      headers = auth_header_for(user)
      params = { disliked_ingredient: { ingredient_id: ingredient.id, priority: "low" } }

      post "/api/v1/users/disliked_ingredients", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["reason"]).to be_nil
    end

    it "同じ食材の重複登録時に422を返す" do
      create(:disliked_ingredient, user: user, ingredient: ingredient)
      headers = auth_header_for(user)

      post "/api/v1/users/disliked_ingredients", params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]["ingredient_id"]).to include("は既に登録されています")
    end

    it "無効なpriorityで422を返す" do
      headers = auth_header_for(user)
      invalid_params = { disliked_ingredient: { ingredient_id: ingredient.id, priority: "invalid" } }

      expect {
        post "/api/v1/users/disliked_ingredients", params: invalid_params, headers: headers, as: :json
      }.not_to raise_error

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]["priority"]).to be_present
      expect(body["errors"]["priority"].first).to include("invalid")
    end

    it "reasonが501文字以上で422を返す" do
      headers = auth_header_for(user)
      invalid_params = {
        disliked_ingredient: {
          ingredient_id: ingredient.id,
          priority: "low",
          reason: "a" * 501
        }
      }

      post "/api/v1/users/disliked_ingredients", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]["reason"]).to include("は500文字以内で入力してください")
    end
  end

  describe "PATCH /api/v1/users/disliked_ingredients/:id" do
    let!(:disliked_ingredient) { create(:disliked_ingredient, user: user, ingredient: ingredient, priority: :low, reason: "元のメモ") }
    let(:update_params) do
      {
        disliked_ingredient: {
          priority: "high",
          reason: "更新されたメモ"
        }
      }
    end

    it "認証なしで401を返す" do
      patch "/api/v1/users/disliked_ingredients/#{disliked_ingredient.id}", params: update_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "有効なパラメータで苦手食材を更新する" do
      headers = auth_header_for(user)

      patch "/api/v1/users/disliked_ingredients/#{disliked_ingredient.id}", params: update_params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(disliked_ingredient.id.to_s)
      expect(body["priority"]).to eq("high")
      expect(body["priority_label"]).to eq("高")
      expect(body["reason"]).to eq("更新されたメモ")

      disliked_ingredient.reload
      expect(disliked_ingredient.priority).to eq("high")
      expect(disliked_ingredient.reason).to eq("更新されたメモ")
    end

    it "他のユーザーの苦手食材を更新しようとすると404を返す" do
      other_disliked = create(:disliked_ingredient, user: other_user, ingredient: cilantro_ingredient)
      headers = auth_header_for(user)

      patch "/api/v1/users/disliked_ingredients/#{other_disliked.id}", params: update_params, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("苦手食材が見つかりません")
    end

    it "存在しないIDで404を返す" do
      headers = auth_header_for(user)

      patch "/api/v1/users/disliked_ingredients/99999", params: update_params, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "reasonが501文字以上で422を返す" do
      headers = auth_header_for(user)
      invalid_params = { disliked_ingredient: { reason: "a" * 501 } }

      patch "/api/v1/users/disliked_ingredients/#{disliked_ingredient.id}", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]["reason"]).to include("は500文字以内で入力してください")
    end

    it "無効なpriorityで422を返す" do
      headers = auth_header_for(user)
      invalid_params = { disliked_ingredient: { priority: "invalid" } }

      expect {
        patch "/api/v1/users/disliked_ingredients/#{disliked_ingredient.id}", params: invalid_params, headers: headers, as: :json
      }.not_to raise_error

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]["priority"]).to be_present
      expect(body["errors"]["priority"].first).to include("invalid")
    end
  end

  describe "DELETE /api/v1/users/disliked_ingredients/:id" do
    let!(:disliked_ingredient) { create(:disliked_ingredient, user: user, ingredient: ingredient) }

    it "認証なしで401を返す" do
      delete "/api/v1/users/disliked_ingredients/#{disliked_ingredient.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "苦手食材を削除する" do
      headers = auth_header_for(user)

      expect {
        delete "/api/v1/users/disliked_ingredients/#{disliked_ingredient.id}", headers: headers, as: :json
      }.to change(DislikedIngredient, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "他のユーザーの苦手食材を削除しようとすると404を返す" do
      other_disliked = create(:disliked_ingredient, user: other_user, ingredient: cilantro_ingredient)
      headers = auth_header_for(user)

      expect {
        delete "/api/v1/users/disliked_ingredients/#{other_disliked.id}", headers: headers, as: :json
      }.not_to change(DislikedIngredient, :count)

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("苦手食材が見つかりません")
    end

    it "存在しないIDで404を返す" do
      headers = auth_header_for(user)

      delete "/api/v1/users/disliked_ingredients/99999", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
