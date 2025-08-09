require 'rails_helper'

RSpec.describe "Api::V1::Users::Registrations", type: :request do
  describe "POST /api/v1/auth/signup" do
    let(:valid_params) do
      {
        user: {
          name: "テストユーザー",
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    let(:invalid_params) do
      {
        user: {
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    context "正常なパラメータの場合" do
      it "新規ユーザーが作成される（200）" do
        expect {
          post "/api/v1/auth/signup", params: valid_params, as: :json
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']['message']).to eq('Signed up successfully.')
      end

      it "確認メールが送信される" do
        expect {
          post "/api/v1/auth/signup", params: valid_params, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
        
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq(["test@example.com"])
        expect(mail.subject).to include("Confirmation instructions")
      end
    end

    context "nameが未入力の場合" do
      it "エラーが返される（422）" do
        post "/api/v1/auth/signup", params: invalid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['status']['message']).to include("Name can't be blank")
      end
    end

    context "重複したメールアドレスの場合" do
      before do
        create(:user, email: "test@example.com")
      end

      it "エラーが返される（422）" do
        post "/api/v1/auth/signup", params: valid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['status']['message']).to include("Email has already been taken")
      end
    end
  end
end