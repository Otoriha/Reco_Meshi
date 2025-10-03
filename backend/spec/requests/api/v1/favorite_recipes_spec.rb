require "rails_helper"

RSpec.describe "Api::V1::FavoriteRecipes", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:headers) { auth_header_for(user) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/favorite_recipes" do
    before do
      create_list(:favorite_recipe, 3, user: user)
      create(:favorite_recipe) # 他ユーザー分
    end

    it "認証なしは401" do
      get "/api/v1/favorite_recipes", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "自ユーザーのお気に入りのみ返す" do
      get "/api/v1/favorite_recipes", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["success"]).to eq(true)
      expect(body["data"].size).to eq(3)
      body["data"].each do |favorite|
        expect(favorite["user_id"]).to eq(user.id)
        expect(favorite["recipe"]).to include("id", "title", "cooking_time", "difficulty", "servings")
      end
      expect(body["meta"]).to include("current_page", "per_page", "total_pages", "total_count")
    end
  end

  describe "POST /api/v1/favorite_recipes" do
    let(:recipe) { create(:recipe, user: user) }

    it "認証なしは401" do
      post "/api/v1/favorite_recipes", params: { favorite_recipe: { recipe_id: recipe.id } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "お気に入りに追加できる" do
      post "/api/v1/favorite_recipes", params: { favorite_recipe: { recipe_id: recipe.id } }, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["success"]).to eq(true)
      expect(body["message"]).to eq("お気に入りに追加しました")
      expect(body["data"]["recipe_id"]).to eq(recipe.id)
    end

    it "重複登録は422" do
      create(:favorite_recipe, user: user, recipe: recipe)

      post "/api/v1/favorite_recipes", params: { favorite_recipe: { recipe_id: recipe.id } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["success"]).to eq(false)
      expect(body["errors"]).to include("レシピIDは既にお気に入りに追加されています")
    end

    it "パラメータ不足は400" do
      expect {
        post "/api/v1/favorite_recipes", params: {}, headers: headers, as: :json
      }.to raise_error(ActionController::ParameterMissing)
    end
  end

  describe "DELETE /api/v1/favorite_recipes/:id" do
    let!(:favorite_recipe) { create(:favorite_recipe, user: user) }

    it "認証なしは401" do
      delete "/api/v1/favorite_recipes/#{favorite_recipe.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "お気に入りを削除できる" do
      expect {
        delete "/api/v1/favorite_recipes/#{favorite_recipe.id}", headers: headers, as: :json
      }.to change(FavoriteRecipe, :count).by(-1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to eq(true)
      expect(body["message"]).to eq("お気に入りから削除しました")
    end

    it "他ユーザーのレコードは404" do
      other_favorite = create(:favorite_recipe)

      expect {
        delete "/api/v1/favorite_recipes/#{other_favorite.id}", headers: headers, as: :json
      }.not_to change(FavoriteRecipe, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end

