require 'rails_helper'

RSpec.describe 'Api::V1::ShoppingListItems', type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let(:shopping_list) { create(:shopping_list, user: user) }
  let(:other_user_list) { create(:shopping_list, user: other_user) }
  let!(:shopping_list_item) { create(:shopping_list_item, shopping_list: shopping_list) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: 'password123' } }, as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  describe 'PATCH /api/v1/shopping_lists/:shopping_list_id/items/:id' do
    let(:url) { "/api/v1/shopping_lists/#{shopping_list.id}/items/#{shopping_list_item.id}" }

    context 'without authentication' do
      it 'returns 401' do
        patch url, params: { shopping_list_item: { is_checked: true } }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      let(:headers) { auth_header_for(user) }

      it 'updates item with valid params' do
        patch url, 
              params: { 
                shopping_list_item: { 
                  is_checked: true, 
                  quantity: 2.5,
                  lock_version: shopping_list_item.lock_version 
                } 
              }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:ok)
        shopping_list_item.reload
        expect(shopping_list_item.is_checked).to be true
        expect(shopping_list_item.quantity).to eq(2.5)
        expect(shopping_list_item.checked_at).to be_present
      end

      it 'returns 422 with invalid params' do
        patch url, 
              params: { 
                shopping_list_item: { 
                  quantity: -1,
                  lock_version: shopping_list_item.lock_version 
                } 
              }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['errors']).to be_present
      end

      it 'returns 409 on stale object error' do
        # 他のプロセスが先に更新したと仮定
        shopping_list_item.update!(quantity: 3.0)
        
        patch url, 
              params: { 
                shopping_list_item: { 
                  is_checked: true,
                  lock_version: 0  # 古いバージョン
                } 
              }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:conflict)
        body = JSON.parse(response.body)
        expect(body['errors'].first['detail']).to include('他のユーザーによって更新されています')
      end

      it 'returns 404 for non-existent shopping list' do
        url = "/api/v1/shopping_lists/999999/items/#{shopping_list_item.id}"
        patch url, 
              params: { shopping_list_item: { is_checked: true } }, 
              headers: headers, 
              as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent item' do
        url = "/api/v1/shopping_lists/#{shopping_list.id}/items/999999"
        patch url, 
              params: { shopping_list_item: { is_checked: true } }, 
              headers: headers, 
              as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 for other user list' do
        other_item = create(:shopping_list_item, shopping_list: other_user_list)
        url = "/api/v1/shopping_lists/#{other_user_list.id}/items/#{other_item.id}"
        
        patch url, 
              params: { shopping_list_item: { is_checked: true } }, 
              headers: headers, 
              as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/shopping_lists/:shopping_list_id/items/:id' do
    let(:url) { "/api/v1/shopping_lists/#{shopping_list.id}/items/#{shopping_list_item.id}" }

    context 'without authentication' do
      it 'returns 401' do
        delete url, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      let(:headers) { auth_header_for(user) }

      it 'deletes shopping list item' do
        expect {
          delete url, headers: headers, as: :json
        }.to change(ShoppingListItem, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 for non-existent shopping list' do
        url = "/api/v1/shopping_lists/999999/items/#{shopping_list_item.id}"
        delete url, headers: headers, as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent item' do
        url = "/api/v1/shopping_lists/#{shopping_list.id}/items/999999"
        delete url, headers: headers, as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 for other user list' do
        other_item = create(:shopping_list_item, shopping_list: other_user_list)
        url = "/api/v1/shopping_lists/#{other_user_list.id}/items/#{other_item.id}"
        
        delete url, headers: headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /api/v1/shopping_lists/:shopping_list_id/items/bulk_update' do
    let!(:item1) { create(:shopping_list_item, shopping_list: shopping_list, is_checked: false) }
    let!(:item2) { create(:shopping_list_item, shopping_list: shopping_list, is_checked: false) }
    let(:url) { "/api/v1/shopping_lists/#{shopping_list.id}/items/bulk_update" }

    context 'without authentication' do
      it 'returns 401' do
        patch url, 
              params: { 
                items: [
                  { id: item1.id, is_checked: true, lock_version: item1.lock_version }
                ] 
              }, 
              as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      let(:headers) { auth_header_for(user) }

      it 'updates multiple items successfully' do
        patch url, 
              params: { 
                items: [
                  { 
                    id: item1.id, 
                    is_checked: true, 
                    lock_version: item1.lock_version 
                  },
                  { 
                    id: item2.id, 
                    is_checked: true, 
                    lock_version: item2.lock_version 
                  }
                ] 
              }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:ok)
        
        body = JSON.parse(response.body)
        expect(body['data'].length).to eq(2)
        
        item1.reload
        item2.reload
        expect(item1.is_checked).to be true
        expect(item2.is_checked).to be true
      end

      it 'returns 422 and rolls back on partial failure' do
        # item1は正常、item2は無効なパラメータ
        patch url, 
              params: { 
                items: [
                  { 
                    id: item1.id, 
                    is_checked: true, 
                    lock_version: item1.lock_version 
                  },
                  { 
                    id: item2.id, 
                    is_checked: true, 
                    lock_version: 999  # 無効なlock_version
                  }
                ] 
              }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        
        # ロールバックにより、item1も更新されていないことを確認
        item1.reload
        item2.reload
        expect(item1.is_checked).to be false
        expect(item2.is_checked).to be false
      end

      it 'returns 409 on stale object error' do
        # item1を他のプロセスが先に更新
        item1.update!(quantity: 5.0)
        
        patch url, 
              params: { 
                items: [
                  { 
                    id: item1.id, 
                    is_checked: true, 
                    lock_version: 0  # 古いバージョン
                  }
                ] 
              }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:conflict)
        body = JSON.parse(response.body)
        expect(body['errors'].first['detail']).to include('他のユーザーによって更新されています')
      end

      it 'returns 404 for non-existent item' do
        patch url, 
              params: { 
                items: [
                  { 
                    id: 999999, 
                    is_checked: true, 
                    lock_version: 0 
                  }
                ] 
              }, 
              headers: headers, 
              as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent shopping list' do
        url = "/api/v1/shopping_lists/999999/items/bulk_update"
        patch url, 
              params: { 
                items: [
                  { 
                    id: item1.id, 
                    is_checked: true, 
                    lock_version: item1.lock_version 
                  }
                ] 
              }, 
              headers: headers, 
              as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 for other user list' do
        other_item = create(:shopping_list_item, shopping_list: other_user_list)
        url = "/api/v1/shopping_lists/#{other_user_list.id}/items/bulk_update"
        
        patch url, 
              params: { 
                items: [
                  { 
                    id: other_item.id, 
                    is_checked: true, 
                    lock_version: other_item.lock_version 
                  }
                ] 
              }, 
              headers: headers, 
              as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end