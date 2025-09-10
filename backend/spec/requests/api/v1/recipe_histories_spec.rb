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
      
      # metaにページネーション情報が含まれていることを確認
      expect(body['meta']).to include('current_page', 'per_page', 'total_pages', 'total_count')
    end

    it 'start_dateパラメータでフィルタできる' do
      headers = auth_header_for(user)
      get '/api/v1/recipe_histories', headers: headers, params: { start_date: Time.current.strftime('%Y-%m-%d') }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].size).to eq(1)
      expect(body['data'].first['memo']).to eq('two')
    end

    it 'end_dateパラメータでフィルタできる' do
      headers = auth_header_for(user)
      yesterday = 1.day.ago.strftime('%Y-%m-%d')
      get '/api/v1/recipe_histories', headers: headers, params: { end_date: yesterday }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].size).to eq(1)
      expect(body['data'].first['memo']).to eq('one')
    end

    it 'recipe_idパラメータでフィルタできる' do
      headers = auth_header_for(user)
      get '/api/v1/recipe_histories', headers: headers, params: { recipe_id: recipe.id }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].size).to eq(2)
      body['data'].each do |history|
        expect(history['recipe_id']).to eq(recipe.id)
      end
    end

    it 'ページネーションパラメータが機能する' do
      headers = auth_header_for(user)
      get '/api/v1/recipe_histories', headers: headers, params: { page: 1, per_page: 1 }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].size).to eq(1)
      expect(body['meta']['current_page']).to eq(1)
      expect(body['meta']['per_page']).to eq(1)
      expect(body['meta']['total_count']).to eq(2)
    end
  end

  describe 'GET /api/v1/recipe_histories/:id' do
    let!(:recipe) { create(:recipe, user: user) }
    let!(:recipe_history) { create(:recipe_history, user: user, recipe: recipe, rating: 4) }

    it '認証なしは401を返す' do
      get "/api/v1/recipe_histories/#{recipe_history.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it '認証済みで自ユーザーのレシピ履歴を取得できる' do
      headers = auth_header_for(user)
      get "/api/v1/recipe_histories/#{recipe_history.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['success']).to eq(true)
      data = body['data']
      expect(data['id']).to eq(recipe_history.id)
      expect(data['rating']).to eq(4)
      expect(data['recipe']).to include('id', 'title')
    end

    it '他ユーザーのレシピ履歴は404を返す' do
      other_user = create(:user, :confirmed)
      other_recipe = create(:recipe, user: other_user)
      other_history = create(:recipe_history, user: other_user, recipe: other_recipe)

      headers = auth_header_for(user)
      get "/api/v1/recipe_histories/#{other_history.id}", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
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

    it 'ratingパラメータ付きで作成できる' do
      headers = auth_header_for(user)
      params = {
        recipe_history: {
          recipe_id: recipe.id,
          memo: 'おいしかった',
          rating: 5,
          cooked_at: Time.current.iso8601
        }
      }

      post '/api/v1/recipe_histories', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body['success']).to eq(true)
      expect(body['data']).to include('rating' => 5)
    end

    it '無効なratingでは422を返す' do
      headers = auth_header_for(user)
      params = {
        recipe_history: {
          recipe_id: recipe.id,
          rating: 10,
          cooked_at: Time.current.iso8601
        }
      }

      post '/api/v1/recipe_histories', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['success']).to eq(false)
    end

    it '不正なパラメータでは422を返す（recipe_id欠如など）' do
      headers = auth_header_for(user)
      post '/api/v1/recipe_histories', params: { recipe_history: { memo: 'x', cooked_at: Time.current.iso8601 } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/recipe_histories/:id' do
    let!(:recipe) { create(:recipe, user: user) }
    let!(:recipe_history) { create(:recipe_history, user: user, recipe: recipe, rating: nil) }

    it '認証なしは401を返す' do
      patch "/api/v1/recipe_histories/#{recipe_history.id}", params: { recipe_history: { rating: 5 } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'ratingを更新できる' do
      headers = auth_header_for(user)
      params = { recipe_history: { rating: 4 } }

      patch "/api/v1/recipe_histories/#{recipe_history.id}", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body['success']).to eq(true)
      expect(body['data']['rating']).to eq(4)
      expect(body['message']).to eq('評価を更新しました')

      recipe_history.reload
      expect(recipe_history.rating).to eq(4)
    end

    it 'ratingをnilに更新できる' do
      recipe_history.update!(rating: 3)
      headers = auth_header_for(user)
      params = { recipe_history: { rating: nil } }

      patch "/api/v1/recipe_histories/#{recipe_history.id}", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body['data']['rating']).to be_nil
    end

    it '無効なratingでは422を返す' do
      headers = auth_header_for(user)
      params = { recipe_history: { rating: 10 } }

      patch "/api/v1/recipe_histories/#{recipe_history.id}", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      body = JSON.parse(response.body)
      expect(body['success']).to eq(false)
    end

    it '他ユーザーのレシピ履歴は404を返す' do
      other_user = create(:user, :confirmed)
      other_recipe = create(:recipe, user: other_user)
      other_history = create(:recipe_history, user: other_user, recipe: other_recipe)

      headers = auth_header_for(user)
      params = { recipe_history: { rating: 5 } }

      patch "/api/v1/recipe_histories/#{other_history.id}", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/recipe_histories/:id' do
    let!(:recipe) { create(:recipe, user: user) }
    let!(:recipe_history) { create(:recipe_history, user: user, recipe: recipe) }

    it '認証なしは401を返す' do
      delete "/api/v1/recipe_histories/#{recipe_history.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it '認証済みで自ユーザーのレシピ履歴を削除できる' do
      headers = auth_header_for(user)
      expect {
        delete "/api/v1/recipe_histories/#{recipe_history.id}", headers: headers, as: :json
      }.to change(RecipeHistory, :count).by(-1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['success']).to eq(true)
      expect(body['message']).to eq('レシピ履歴を削除しました')
    end

    it '他ユーザーのレシピ履歴は404を返す' do
      other_user = create(:user, :confirmed)
      other_recipe = create(:recipe, user: other_user)
      other_history = create(:recipe_history, user: other_user, recipe: other_recipe)

      headers = auth_header_for(user)
      expect {
        delete "/api/v1/recipe_histories/#{other_history.id}", headers: headers, as: :json
      }.not_to change(RecipeHistory, :count)
      
      expect(response).to have_http_status(:not_found)
    end
  end
end
