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
    it 'returns 401 without authentication' do
      post '/api/v1/user_ingredients', params: { user_ingredient: { ingredient_id: ingredient.id, quantity: 1.0 } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

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

    it 'returns 401 without authentication' do
      put "/api/v1/user_ingredients/#{own_record.id}", params: { user_ingredient: { quantity: 1.0 } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

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

    it 'returns 404 when record not found' do
      headers = auth_header_for(user)
      put "/api/v1/user_ingredients/999999", params: { user_ingredient: { quantity: 1.0 } }, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 on validation error' do
      headers = auth_header_for(user)
      put "/api/v1/user_ingredients/#{own_record.id}", params: { user_ingredient: { quantity: -5 } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/user_ingredients/:id' do
    let!(:own_record) { create(:user_ingredient, user: user, ingredient: ingredient) }
    let!(:others_record) { create(:user_ingredient, user: other_user, ingredient: ingredient) }

    it 'returns 401 without authentication' do
      delete "/api/v1/user_ingredients/#{own_record.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'deletes own inventory' do
      headers = auth_header_for(user)
      delete "/api/v1/user_ingredients/#{own_record.id}", headers: headers, as: :json
      expect(response).to have_http_status(:no_content)
    end

    it 'forbids deleting others inventory' do
      headers = auth_header_for(user)
      delete "/api/v1/user_ingredients/#{others_record.id}", headers: headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 when record not found' do
      headers = auth_header_for(user)
      delete "/api/v1/user_ingredients/999999", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'filters and sorting' do
    let!(:veg) { create(:ingredient, :vegetable) }
    let!(:meat) { create(:ingredient, :meat) }
    let!(:ui1) { create(:user_ingredient, user: user, ingredient: veg, status: 'available', expiry_date: Date.current + 2.days, quantity: 1.0) }
    let!(:ui2) { create(:user_ingredient, user: user, ingredient: veg, status: 'expired', expiry_date: Date.current - 1.day, quantity: 3.0) }
    let!(:ui3) { create(:user_ingredient, user: user, ingredient: meat, status: 'available', expiry_date: nil, quantity: 2.0) }

    it 'filters by status' do
      headers = auth_header_for(user)
      get '/api/v1/user_ingredients', params: { status: 'available' }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].all? { |d| d['status'] == 'available' }).to be true
    end

    it 'filters by category' do
      headers = auth_header_for(user)
      get '/api/v1/user_ingredients', params: { category: 'meat' }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].all? { |d| d['ingredient']['category'] == 'meat' }).to be true
    end

    it 'sorts by expiry_date with nils last' do
      headers = auth_header_for(user)
      get '/api/v1/user_ingredients', params: { sort_by: 'expiry_date' }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      dates = body['data'].map { |d| d['expiry_date'] }
      # Non-nil come first in ascending order, nils last
      expect(dates.compact).to eq(dates.compact.sort)
      expect(dates.last).to be_nil
    end
  end
end
