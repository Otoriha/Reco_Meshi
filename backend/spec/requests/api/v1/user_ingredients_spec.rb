require 'rails_helper'

RSpec.describe 'Api::V1::UserIngredients', type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let!(:ingredient) { create(:ingredient) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: 'password123' } }, as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  describe 'GET /api/v1/user_ingredients' do
    before do
      create_list(:user_ingredient, 2, user: user, ingredient: ingredient)
      create(:user_ingredient, user: other_user, ingredient: ingredient) # 他ユーザー分
    end

    it 'returns 401 without authentication' do
      get '/api/v1/user_ingredients', as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists only current user inventory' do
      headers = auth_header_for(user)
      get '/api/v1/user_ingredients', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']).to be_an(Array)
      expect(body['data'].length).to eq(2)
      expect(body['data'].all? { |d| d['user_id'] == user.id }).to be true
    end

    it 'supports grouping by category' do
      headers = auth_header_for(user)
      get '/api/v1/user_ingredients', params: { group_by: 'category' }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']).to be_a(Hash)
    end
  end

  describe 'POST /api/v1/user_ingredients' do
    it 'creates inventory for current user' do
      headers = auth_header_for(user)
      post '/api/v1/user_ingredients', params: { user_ingredient: { ingredient_id: ingredient.id, quantity: 2.5 } }, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body['data']['user_id']).to eq(user.id)
      expect(body['data']['ingredient_id']).to eq(ingredient.id)
    end

    it 'returns 422 for invalid params' do
      headers = auth_header_for(user)
      post '/api/v1/user_ingredients', params: { user_ingredient: { ingredient_id: nil, quantity: -1 } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT /api/v1/user_ingredients/:id' do
    let!(:own_record) { create(:user_ingredient, user: user, ingredient: ingredient) }
    let!(:others_record) { create(:user_ingredient, user: other_user, ingredient: ingredient) }

    it 'updates own inventory' do
      headers = auth_header_for(user)
      put "/api/v1/user_ingredients/#{own_record.id}", params: { user_ingredient: { quantity: 9.9 } }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']['quantity']).to eq(9.9)
    end

    it 'forbids updating others inventory' do
      headers = auth_header_for(user)
      put "/api/v1/user_ingredients/#{others_record.id}", params: { user_ingredient: { quantity: 1.0 } }, headers: headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/user_ingredients/:id' do
    let!(:own_record) { create(:user_ingredient, user: user, ingredient: ingredient) }

    it 'deletes own inventory' do
      headers = auth_header_for(user)
      delete "/api/v1/user_ingredients/#{own_record.id}", headers: headers, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end
end

