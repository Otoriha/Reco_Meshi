require 'rails_helper'

RSpec.describe 'Api::V1::Ingredients', type: :request do
  let(:user) { create(:user, :confirmed) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: 'password123' } }, as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  describe 'GET /api/v1/ingredients' do
    before do
      create_list(:ingredient, 3)
    end

    it 'returns 401 without authentication' do
      get '/api/v1/ingredients', as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns ingredients list for authenticated user' do
      headers = auth_header_for(user)
      get '/api/v1/ingredients', headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']).to be_an(Array)
      expect(body['meta']).to include('total', 'page', 'per_page')
    end
  end

  describe 'POST /api/v1/ingredients' do
    let(:valid_params) { { ingredient: { name: 'にんじん', category: 'vegetables', unit: '本', emoji: '🥕' } } }

    it 'creates an ingredient with valid params' do
      headers = auth_header_for(user)
      post '/api/v1/ingredients', params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body['data']['name']).to eq('にんじん')
    end

    it 'returns 422 for invalid params' do
      headers = auth_header_for(user)
      post '/api/v1/ingredients', params: { ingredient: { category: 'vegetables', unit: '本' } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT /api/v1/ingredients/:id' do
    let!(:ingredient) { create(:ingredient) }

    it 'updates an ingredient' do
      headers = auth_header_for(user)
      put "/api/v1/ingredients/#{ingredient.id}", params: { ingredient: { name: '新しい名前' } }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']['name']).to eq('新しい名前')
    end

    it 'returns 404 for non-existing ingredient' do
      headers = auth_header_for(user)
      put "/api/v1/ingredients/999999", params: { ingredient: { name: 'X' } }, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/ingredients/:id' do
    let!(:ingredient) { create(:ingredient) }

    it 'deletes an ingredient' do
      headers = auth_header_for(user)
      delete "/api/v1/ingredients/#{ingredient.id}", headers: headers, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end
end

