require 'rails_helper'

RSpec.describe 'Api::V1::RecipeHistories', type: :request do
  let(:user) { create(:user, :confirmed) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: 'password123' } }, as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  describe 'GET /api/v1/recipe_histories' do
    let!(:recipe) { create(:recipe, user: user) }

    before do
      # 自ユーザー2件 + 他ユーザー1件
      create(:recipe_history, user: user, recipe: recipe, cooked_at: 1.day.ago, memo: 'one')
      create(:recipe_history, user: user, recipe: recipe, cooked_at: Time.current, memo: 'two')
      other_user = create(:user, :confirmed)
      other_recipe = create(:recipe, user: other_user)
      create(:recipe_history, user: other_user, recipe: other_recipe, cooked_at: Time.current)
    end

    it '認証なしは401を返す' do
      get '/api/v1/recipe_histories', as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it '認証済みで自ユーザーの履歴のみを新しい順で返す' do
      headers = auth_header_for(user)
      get '/api/v1/recipe_histories', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['success']).to eq(true)
      data = body['data']
      expect(data).to be_an(Array)
      expect(data.size).to eq(2)

      cooked_times = data.map { |h| Time.parse(h['cooked_at']) }
      expect(cooked_times.first).to be >= cooked_times.last
      # 最低限の埋め込みレシピ情報
      expect(data.first['recipe']).to include('id', 'title')
    end
  end

  describe 'POST /api/v1/recipe_histories' do
    let!(:recipe) { create(:recipe, user: user) }

    it '認証なしは401を返す' do
      post '/api/v1/recipe_histories', params: { recipe_history: { recipe_id: recipe.id } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it '有効なパラメータで作成できる' do
      headers = auth_header_for(user)
      params = {
        recipe_history: {
          recipe_id: recipe.id,
          memo: 'また作りたい',
          cooked_at: Time.current.iso8601
        }
      }

      post '/api/v1/recipe_histories', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body['success']).to eq(true)
      expect(body['data']).to include('recipe_id' => recipe.id, 'memo' => 'また作りたい')
    end

    it '不正なパラメータでは422を返す（recipe_id欠如など）' do
      headers = auth_header_for(user)
      post '/api/v1/recipe_histories', params: { recipe_history: { memo: 'x', cooked_at: Time.current.iso8601 } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

