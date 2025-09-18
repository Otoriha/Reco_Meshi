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
      get "/api/v1/recipe_histories?start_date=#{Time.current.strftime('%Y-%m-%d')}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].size).to eq(1)
      expect(body['data'].first['memo']).to eq('two')
    end

    it 'end_dateパラメータでフィルタできる' do
      headers = auth_header_for(user)
      yesterday = 1.day.ago.strftime('%Y-%m-%d')
      get "/api/v1/recipe_histories?end_date=#{yesterday}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].size).to eq(1)
      expect(body['data'].first['memo']).to eq('one')
    end

    it 'recipe_idパラメータでフィルタできる' do
      headers = auth_header_for(user)
      get "/api/v1/recipe_histories?recipe_id=#{recipe.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].size).to eq(2)
      body['data'].each do |history|
        expect(history['recipe_id']).to eq(recipe.id)
      end
    end

    it 'ページネーションパラメータが機能する' do
      headers = auth_header_for(user)
      get "/api/v1/recipe_histories?page=1&per_page=1", headers: headers, as: :json

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

    it 'フラットJSONでは400を返す（ParameterMissing）' do
      headers = auth_header_for(user)
      post '/api/v1/recipe_histories', params: { recipe_id: recipe.id, memo: 'フラット形式' }, headers: headers, as: :json
      expect(response).to have_http_status(:bad_request)
      body = JSON.parse(response.body)
      expect(body['error']).to include('param is missing or the value is empty: recipe_history')
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

  describe 'GET /api/v1/recipe_histories (rated_only フィルタ)' do
    let(:headers) { auth_header_for(user) }
    let!(:recipe) { create(:recipe, user: user) }

    before do
      create(:recipe_history, user: user, recipe: recipe, rating: nil, cooked_at: 2.days.ago)
      create(:recipe_history, user: user, recipe: recipe, rating: 5, cooked_at: 3.days.ago)
    end

    it 'rated_only=true で評価済みのみを返す' do
      get '/api/v1/recipe_histories?rated_only=true', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']).to all(satisfy { |h| !h['rating'].nil? })
    end

    it 'rated_only=false で全件返す' do
      get '/api/v1/recipe_histories?rated_only=false', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      # 2件 + 前のテストで作成したものを考慮せず、このブロック内の件数を検証
      # このブロックのbeforeで2件作成しているため、最低2件は返る
      expect(body['data'].size).to be >= 2
    end
  end

  describe 'GET /api/v1/recipe_histories (境界値・バリデーションテスト)' do
    let(:headers) { auth_header_for(user) }
    let!(:recipe) { create(:recipe, user: user) }

    before do
      create(:recipe_history, user: user, recipe: recipe, cooked_at: Time.current)
    end

    it 'per_page=0の場合は1にクランプされる' do
      get '/api/v1/recipe_histories?per_page=0', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['meta']['per_page']).to eq(1)
    end

    it 'per_page=負数の場合は1にクランプされる' do
      get '/api/v1/recipe_histories?per_page=-5', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['meta']['per_page']).to eq(1)
    end

    it 'per_page=101の場合は100にクランプされる' do
      get '/api/v1/recipe_histories?per_page=101', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['meta']['per_page']).to eq(100)
    end

    it '不正な日付形式の場合はフィルタが無視される' do
      get '/api/v1/recipe_histories?start_date=invalid-date', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      # フィルタが無視されるため、全ての履歴が返される
      expect(body['data'].size).to be >= 1
    end

    it '空文字列の日付パラメータの場合はフィルタが無視される' do
      get '/api/v1/recipe_histories?start_date=&end_date=', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      # フィルタが無視されるため、全ての履歴が返される
      expect(body['data'].size).to be >= 1
    end
  end
end
