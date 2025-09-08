require 'rails_helper'

RSpec.describe 'Api::V1::Recipes', type: :request do
  let(:user) { create(:user, :confirmed) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: 'password123' } }, as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  describe 'GET /api/v1/recipes' do
    before do
      # 認証ユーザーのレシピを作成（コントローラはcurrent_userのレシピのみを返す）
      create_list(:recipe, 2, user: user)
      other_user = create(:user, :confirmed)
      create(:recipe, user: other_user) # このレシピは返されない
    end

    it '認証なしは401を返す' do
      get '/api/v1/recipes', as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it '認証済みでレシピ一覧を返す（最大50件）' do
      headers = auth_header_for(user)
      get '/api/v1/recipes', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['success']).to eq(true)
      expect(body['data']).to be_an(Array)
      expect(body['data'].size).to eq(2) # current_userのレシピのみ返される

      sample = body['data'].first
      expect(sample).to include('id', 'title', 'cooking_time', 'formatted_cooking_time', 'difficulty', 'difficulty_display', 'servings', 'created_at')
    end
  end

  describe 'GET /api/v1/recipes/:id' do
    let!(:recipe) { create(:recipe, user: user) }
    let!(:ingredient1) { create(:ingredient, name: 'にんじん', unit: '本') }
    let!(:ri1) { create(:recipe_ingredient, recipe: recipe, ingredient: ingredient1, amount: 1, unit: '本', is_optional: false) }
    let!(:ri2) { create(:recipe_ingredient, :without_master, recipe: recipe, ingredient: nil, ingredient_name: '塩', amount: nil, unit: nil, is_optional: true) }

    it '認証なしは401を返す' do
      get "/api/v1/recipes/#{recipe.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it '認証済みでレシピ詳細を返す（材料・手順を含む）' do
      headers = auth_header_for(user)
      get "/api/v1/recipes/#{recipe.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['success']).to eq(true)
      data = body['data']

      expect(data).to include('id' => recipe.id, 'title' => recipe.title)
      expect(data['steps']).to be_an(Array)
      # factoryのstepsは構造化→配列文字列化される想定
      expect(data['steps']).to all(be_a(String))

      expect(data['ingredients']).to be_an(Array)
      names = data['ingredients'].map { |i| i['name'] }
      expect(names).to include('にんじん', '塩')
    end
  end
end

