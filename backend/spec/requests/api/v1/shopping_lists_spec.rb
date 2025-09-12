require 'rails_helper'

RSpec.describe 'Api::V1::ShoppingLists', type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: 'password123' } }, as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  describe 'GET /api/v1/shopping_lists' do
    let!(:shopping_lists) { create_list(:shopping_list, 3, user: user) }
    let!(:other_user_list) { create(:shopping_list, user: other_user) }

    context 'without authentication' do
      it 'returns 401' do
        get '/api/v1/shopping_lists', as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      let(:headers) { auth_header_for(user) }

      it 'returns user shopping lists only' do
        get '/api/v1/shopping_lists', headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['data'].length).to eq(3)
        
        returned_ids = body['data'].map { |list| list['id'].to_i }
        expect(returned_ids).to match_array(shopping_lists.map(&:id))
        expect(returned_ids).not_to include(other_user_list.id)
      end

      it 'filters by status when provided' do
        completed_list = create(:shopping_list, :completed, user: user)
        
        get '/api/v1/shopping_lists', 
            params: { status: 'completed' },
            headers: headers, 
            as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['data'].length).to eq(1)
        expect(body['data'].first['id']).to eq(completed_list.id.to_s)
      end

      it 'filters by recipe_id when provided' do
        recipe = create(:recipe, user: user)
        recipe_list = create(:shopping_list, :with_recipe, user: user, recipe: recipe)
        
        get '/api/v1/shopping_lists', 
            params: { recipe_id: recipe.id },
            headers: headers, 
            as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['data'].length).to eq(1)
        expect(body['data'].first['id']).to eq(recipe_list.id.to_s)
      end

      it 'supports pagination' do
        create_list(:shopping_list, 25, user: user)
        
        get '/api/v1/shopping_lists', 
            params: { page: 1, per_page: 10 },
            headers: headers, 
            as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['data'].length).to eq(10)
      end
    end
  end

  describe 'GET /api/v1/shopping_lists/:id' do
    let(:shopping_list) { create(:shopping_list, :with_items, user: user) }
    let(:other_user_list) { create(:shopping_list, user: other_user) }

    context 'without authentication' do
      it 'returns 401' do
        get "/api/v1/shopping_lists/#{shopping_list.id}", as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      let(:headers) { auth_header_for(user) }

      it 'returns shopping list with items' do
        get "/api/v1/shopping_lists/#{shopping_list.id}", headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['data']['id']).to eq(shopping_list.id.to_s)
        expect(body['data']['attributes']).to include(
          'status', 'title', 'display_title', 'completion_percentage'
        )
        expect(body['included']).to be_present
      end

      it 'returns 404 for non-existent list' do
        get "/api/v1/shopping_lists/999999", headers: headers, as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 for other user list' do
        get "/api/v1/shopping_lists/#{other_user_list.id}", headers: headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/shopping_lists' do
    context 'without authentication' do
      it 'returns 401' do
        post '/api/v1/shopping_lists', params: { shopping_list: { title: 'Test' } }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      let(:headers) { auth_header_for(user) }

      context 'manual creation' do
        let(:valid_params) do
          {
            shopping_list: {
              title: 'Manual List',
              note: 'Test note',
              status: 'pending'
            }
          }
        end

        it 'creates shopping list with valid params' do
          expect {
            post '/api/v1/shopping_lists', params: valid_params, headers: headers, as: :json
          }.to change(ShoppingList, :count).by(1)

          expect(response).to have_http_status(:created)
          body = JSON.parse(response.body)
          expect(body['data']['attributes']['title']).to eq('Manual List')
          expect(body['data']['attributes']['note']).to eq('Test note')
        end

        it 'returns 422 with invalid params' do
          invalid_params = { shopping_list: { title: 'x' * 101 } }
          
          post '/api/v1/shopping_lists', params: invalid_params, headers: headers, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body['errors']).to be_present
        end
      end

      context 'recipe-based creation' do
        let(:recipe) { create(:recipe, user: user) }
        let(:onion) { create(:ingredient, name: '玉ねぎ', unit: '個') }
        let!(:recipe_ingredient) { create(:recipe_ingredient, recipe: recipe, ingredient: onion, amount: 2) }

        it 'creates shopping list from recipe' do
          expect {
            post '/api/v1/shopping_lists', 
                 params: { recipe_id: recipe.id }, 
                 headers: headers, 
                 as: :json
          }.to change(ShoppingList, :count).by(1)

          expect(response).to have_http_status(:created)
          
          shopping_list = ShoppingList.last
          expect(shopping_list.recipe).to eq(recipe)
          expect(shopping_list.shopping_list_items.count).to eq(1)
        end

        it 'returns 404 for non-existent recipe' do
          post '/api/v1/shopping_lists', 
               params: { recipe_id: 999999 }, 
               headers: headers, 
               as: :json
          
          expect(response).to have_http_status(:not_found)
        end

        it 'returns 404 for other user recipe' do
          other_recipe = create(:recipe, user: other_user)
          
          post '/api/v1/shopping_lists', 
               params: { recipe_id: other_recipe.id }, 
               headers: headers, 
               as: :json
          
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'PATCH /api/v1/shopping_lists/:id' do
    let(:shopping_list) { create(:shopping_list, user: user, title: 'Original Title') }
    let(:other_user_list) { create(:shopping_list, user: other_user) }

    context 'without authentication' do
      it 'returns 401' do
        patch "/api/v1/shopping_lists/#{shopping_list.id}", 
              params: { shopping_list: { title: 'New Title' } }, 
              as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      let(:headers) { auth_header_for(user) }

      it 'updates shopping list with valid params' do
        patch "/api/v1/shopping_lists/#{shopping_list.id}", 
              params: { shopping_list: { title: 'Updated Title', status: 'completed' } }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:ok)
        shopping_list.reload
        expect(shopping_list.title).to eq('Updated Title')
        expect(shopping_list.status).to eq('completed')
      end

      it 'returns 422 with invalid params' do
        patch "/api/v1/shopping_lists/#{shopping_list.id}", 
              params: { shopping_list: { title: 'x' * 101 } }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 404 for non-existent list' do
        patch "/api/v1/shopping_lists/999999", 
              params: { shopping_list: { title: 'New Title' } }, 
              headers: headers, 
              as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 for other user list' do
        patch "/api/v1/shopping_lists/#{other_user_list.id}", 
              params: { shopping_list: { title: 'New Title' } }, 
              headers: headers, 
              as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/shopping_lists/:id' do
    let!(:shopping_list) { create(:shopping_list, user: user) }
    let(:other_user_list) { create(:shopping_list, user: other_user) }

    context 'without authentication' do
      it 'returns 401' do
        delete "/api/v1/shopping_lists/#{shopping_list.id}", as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      let(:headers) { auth_header_for(user) }

      it 'deletes shopping list' do
        expect {
          delete "/api/v1/shopping_lists/#{shopping_list.id}", headers: headers, as: :json
        }.to change(ShoppingList, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 for non-existent list' do
        delete "/api/v1/shopping_lists/999999", headers: headers, as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 for other user list' do
        delete "/api/v1/shopping_lists/#{other_user_list.id}", headers: headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end