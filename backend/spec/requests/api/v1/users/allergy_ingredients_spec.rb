require "rails_helper"

RSpec.describe "Api::V1::Users::AllergyIngredients", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed, email: "other@example.com") }
  let(:ingredient) { create(:ingredient, name: "卵") }
  let(:soba_ingredient) { create(:ingredient, name: "そば") }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/users/allergy_ingredients" do
    let!(:allergy1) { create(:allergy_ingredient, user: user, ingredient: ingredient) }
    let!(:allergy2) { create(:allergy_ingredient, user: user, ingredient: soba_ingredient) }
    let!(:other_allergy) { create(:allergy_ingredient, user: other_user, ingredient: ingredient) }

    it "認証なしで401を返す" do
      get "/api/v1/users/allergy_ingredients", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "認証済みユーザーのアレルギー食材一覧を返す" do
      headers = auth_header_for(user)
      get "/api/v1/users/allergy_ingredients", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(2)

      # 最新順で返される
      expect(body.first["ingredient_id"]).to eq(soba_ingredient.id)
      expect(body.first["ingredient"]["name"]).to eq("そば")

      expect(body.last["ingredient_id"]).to eq(ingredient.id)
    end

    it "レスポンスにseverityが含まれないこと" do
      headers = auth_header_for(user)
      get "/api/v1/users/allergy_ingredients", headers: headers, as: :json

      body = JSON.parse(response.body)
      expect(body.first).not_to have_key("severity")
      expect(body.first).not_to have_key("severity_label")
    end

    it "他のユーザーのアレルギー食材は返さない" do
      headers = auth_header_for(user)
      get "/api/v1/users/allergy_ingredients", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      user_ids = body.map { |item| item["user_id"] }.uniq
      expect(user_ids).to eq([ user.id ])
      expect(user_ids).not_to include(other_user.id)
    end
  end

  describe "POST /api/v1/users/allergy_ingredients" do
    let(:valid_params) do
      {
        allergy_ingredient: {
          ingredient_id: ingredient.id,
          note: "食べると喉が痒くなる"
        }
      }
    end

    it "認証なしで401を返す" do
      post "/api/v1/users/allergy_ingredients", params: valid_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "有効なパラメータでアレルギー食材を登録する" do
      headers = auth_header_for(user)

      expect {
        post "/api/v1/users/allergy_ingredients", params: valid_params, headers: headers, as: :json
      }.to change(AllergyIngredient, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["user_id"]).to eq(user.id)
      expect(body["ingredient_id"]).to eq(ingredient.id)
      expect(body["note"]).to eq("食べると喉が痒くなる")
      expect(body["ingredient"]["name"]).to eq("卵")
      expect(body).not_to have_key("severity")
      expect(body).not_to have_key("severity_label")
    end

    it "noteなしでも登録できる" do
      headers = auth_header_for(user)
      params = { allergy_ingredient: { ingredient_id: ingredient.id } }

      post "/api/v1/users/allergy_ingredients", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["note"]).to be_nil
    end

    it "クライアントから誤ってseverityを送信しても無視される" do
      headers = auth_header_for(user)
      params = { allergy_ingredient: { ingredient_id: ingredient.id, severity: "moderate", note: "テストメモ" } }

      post "/api/v1/users/allergy_ingredients", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["note"]).to eq("テストメモ")
      expect(body).not_to have_key("severity")
      expect(body).not_to have_key("severity_label")
    end

    it "同じ食材の重複登録時に422を返す" do
      create(:allergy_ingredient, user: user, ingredient: ingredient)
      headers = auth_header_for(user)

      post "/api/v1/users/allergy_ingredients", params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]["ingredient_id"]).to include("は既に登録されています")
    end

    it "noteが501文字以上で422を返す" do
      headers = auth_header_for(user)
      invalid_params = {
        allergy_ingredient: {
          ingredient_id: ingredient.id,
          note: "a" * 501
        }
      }

      post "/api/v1/users/allergy_ingredients", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]["note"]).to include("は500文字以内で入力してください")
    end
  end

  describe "PATCH /api/v1/users/allergy_ingredients/:id" do
    let!(:allergy_ingredient) { create(:allergy_ingredient, user: user, ingredient: ingredient, note: "元のメモ") }
    let(:update_params) do
      {
        allergy_ingredient: {
          note: "更新されたメモ"
        }
      }
    end

    it "認証なしで401を返す" do
      patch "/api/v1/users/allergy_ingredients/#{allergy_ingredient.id}", params: update_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "有効なパラメータでアレルギー食材を更新する" do
      headers = auth_header_for(user)

      patch "/api/v1/users/allergy_ingredients/#{allergy_ingredient.id}", params: update_params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["note"]).to eq("更新されたメモ")
      expect(body).not_to have_key("severity")
      expect(body).not_to have_key("severity_label")

      allergy_ingredient.reload
      expect(allergy_ingredient.note).to eq("更新されたメモ")
    end

    it "クライアントから誤ってseverityを送信しても無視される" do
      headers = auth_header_for(user)
      params = { allergy_ingredient: { severity: "severe", note: "更新メモ" } }

      patch "/api/v1/users/allergy_ingredients/#{allergy_ingredient.id}", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["note"]).to eq("更新メモ")
      expect(body).not_to have_key("severity")
      expect(body).not_to have_key("severity_label")
    end

    it "他のユーザーのアレルギー食材を更新しようとすると404を返す" do
      other_allergy = create(:allergy_ingredient, user: other_user, ingredient: soba_ingredient)
      headers = auth_header_for(user)

      patch "/api/v1/users/allergy_ingredients/#{other_allergy.id}", params: update_params, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("アレルギー食材が見つかりません")
    end

    it "存在しないIDで404を返す" do
      headers = auth_header_for(user)

      patch "/api/v1/users/allergy_ingredients/99999", params: update_params, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "noteが501文字以上で422を返す" do
      headers = auth_header_for(user)
      invalid_params = { allergy_ingredient: { note: "a" * 501 } }

      patch "/api/v1/users/allergy_ingredients/#{allergy_ingredient.id}", params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]["note"]).to include("は500文字以内で入力してください")
    end

  end

  describe "DELETE /api/v1/users/allergy_ingredients/:id" do
    let!(:allergy_ingredient) { create(:allergy_ingredient, user: user, ingredient: ingredient) }

    it "認証なしで401を返す" do
      delete "/api/v1/users/allergy_ingredients/#{allergy_ingredient.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "アレルギー食材を削除する" do
      headers = auth_header_for(user)

      expect {
        delete "/api/v1/users/allergy_ingredients/#{allergy_ingredient.id}", headers: headers, as: :json
      }.to change(AllergyIngredient, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "他のユーザーのアレルギー食材を削除しようとすると404を返す" do
      other_allergy = create(:allergy_ingredient, user: other_user, ingredient: soba_ingredient)
      headers = auth_header_for(user)

      expect {
        delete "/api/v1/users/allergy_ingredients/#{other_allergy.id}", headers: headers, as: :json
      }.not_to change(AllergyIngredient, :count)

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("アレルギー食材が見つかりません")
    end

    it "存在しないIDで404を返す" do
      headers = auth_header_for(user)

      delete "/api/v1/users/allergy_ingredients/99999", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
