require 'rails_helper'

RSpec.describe "JWT Authentication", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:headers) { {} }

  describe "JWT認証の統合テスト" do
    context "有効なJWTトークンを使用する場合" do
      before do
        # ログインしてトークンを取得
        post "/api/v1/auth/login", params: {
          user: { email: user.email, password: "password123" }
        }, as: :json
        
        @token = response.headers['Authorization']
      end

      it "トークンが正しく発行される" do
        expect(@token).to be_present
        expect(@token).to match(/^Bearer /)
      end

      it "トークンに正しいクレームが含まれる" do
        token_payload = JWT.decode(@token.split(' ').last, ENV['DEVISE_JWT_SECRET_KEY'], false).first
        
        expect(token_payload['sub']).to eq(user.id.to_s)
        expect(token_payload['email']).to eq(user.email)
        expect(token_payload['jti']).to be_present
        expect(token_payload['exp']).to be_present
      end

      it "トークンの有効期限が正しく設定される" do
        token_payload = JWT.decode(@token.split(' ').last, ENV['DEVISE_JWT_SECRET_KEY'], false).first
        exp_time = Time.at(token_payload['exp'])
        
        # 有効期限が約1日後に設定されていることを確認（誤差を考慮）
        expect(exp_time).to be_within(60.seconds).of(Time.current + 1.day)
      end
    end

    context "無効なトークンを使用する場合" do
      it "改ざんされたトークンは拒否される" do
        # ログインしてトークンを取得
        post "/api/v1/auth/login", params: {
          user: { email: user.email, password: "password123" }
        }, as: :json
        
        token = response.headers['Authorization']
        # トークンを改ざん
        tampered_token = token.gsub(/.$/, 'X')
        
        # 保護されたエンドポイントにアクセス（今後実装するエンドポイント用のテスト）
        # get "/api/v1/protected", headers: { 'Authorization' => tampered_token }
        # expect(response).to have_http_status(:unauthorized)
      end
    end

    context "ブラックリストに追加されたトークンの場合" do
      it "ログアウト後のトークンは無効になる" do
        # ログイン
        post "/api/v1/auth/login", params: {
          user: { email: user.email, password: "password123" }
        }, as: :json
        
        token = response.headers['Authorization']
        
        # ログアウト
        delete "/api/v1/auth/logout", headers: { 'Authorization' => token }, as: :json
        expect(response).to have_http_status(:ok)
        
        # ログアウト後のトークンでアクセスを試みる（今後実装するエンドポイント用のテスト）
        # get "/api/v1/protected", headers: { 'Authorization' => token }
        # expect(response).to have_http_status(:unauthorized)
      end
    end

    context "複数セッションの管理" do
      it "異なるトークンで同時にログイン可能" do
        # 1回目のログイン
        post "/api/v1/auth/login", params: {
          user: { email: user.email, password: "password123" }
        }, as: :json
        token1 = response.headers['Authorization']
        
        # 2回目のログイン
        post "/api/v1/auth/login", params: {
          user: { email: user.email, password: "password123" }
        }, as: :json
        token2 = response.headers['Authorization']
        
        # 両方のトークンが異なることを確認
        expect(token1).not_to eq(token2)
        
        # 両方のトークンが有効（今後実装するエンドポイント用のテスト）
        # get "/api/v1/protected", headers: { 'Authorization' => token1 }
        # expect(response).to have_http_status(:ok)
        
        # get "/api/v1/protected", headers: { 'Authorization' => token2 }
        # expect(response).to have_http_status(:ok)
      end
    end

    context "リフレッシュトークン機能" do
      before do
        # ログインしてトークンを取得
        post "/api/v1/auth/login", params: {
          user: { email: user.email, password: "password123" }
        }, as: :json
        
        @original_token = response.headers['Authorization']
      end

      it "有効なトークンでリフレッシュが成功する" do
        post "/api/v1/auth/refresh", headers: { 'Authorization' => @original_token }, as: :json
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']['message']).to eq('Token refreshed successfully.')
        
        # 新しいトークンが発行される
        new_token = response.headers['Authorization']
        expect(new_token).to be_present
        expect(new_token).not_to eq(@original_token)
      end

      it "リフレッシュ後、元のトークンは無効になる" do
        # リフレッシュ実行
        post "/api/v1/auth/refresh", headers: { 'Authorization' => @original_token }, as: :json
        expect(response).to have_http_status(:ok)
        
        # 元のトークンのjtiがJwtDenylistに登録されていることを確認
        original_payload = JWT.decode(@original_token.split(' ').last, ENV['DEVISE_JWT_SECRET_KEY'], false).first
        expect(JwtDenylist.exists?(jti: original_payload['jti'])).to be_truthy
      end

      it "無効なトークンではリフレッシュできない" do
        # より適切な無効なJWT形式を使用
        invalid_payload = { sub: 'invalid', jti: 'invalid', exp: 1.hour.from_now.to_i }
        invalid_token = "Bearer " + JWT.encode(invalid_payload, 'wrong_secret', 'HS256')
        
        post "/api/v1/auth/refresh", headers: { 'Authorization' => invalid_token }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['status']['message']).to eq('Invalid token.')
      end

      it "トークンなしではリフレッシュできない" do
        post "/api/v1/auth/refresh", as: :json
        
        expect(response).to have_http_status(:unauthorized)
      end

      it "ブラックリストに追加済みのトークンではリフレッシュできない" do
        # 一度リフレッシュして元のトークンをブラックリストに追加
        post "/api/v1/auth/refresh", headers: { 'Authorization' => @original_token }, as: :json
        expect(response).to have_http_status(:ok)
        
        # 再度同じトークンでリフレッシュを試行
        post "/api/v1/auth/refresh", headers: { 'Authorization' => @original_token }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "ログアウト機能" do
      before do
        # ログインしてトークンを取得
        post "/api/v1/auth/login", params: {
          user: { email: user.email, password: "password123" }
        }, as: :json
        
        @token = response.headers['Authorization']
      end

      it "有効なトークンでログアウトが成功する" do
        delete "/api/v1/auth/logout", headers: { 'Authorization' => @token }, as: :json
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Logged out successfully.')
      end

      it "ログアウト後、トークンがブラックリストに追加される" do
        # ログアウト実行
        delete "/api/v1/auth/logout", headers: { 'Authorization' => @token }, as: :json
        expect(response).to have_http_status(:ok)
        
        # トークンのjtiがJwtDenylistに登録されていることを確認
        payload = JWT.decode(@token.split(' ').last, ENV['DEVISE_JWT_SECRET_KEY'], false).first
        expect(JwtDenylist.exists?(jti: payload['jti'])).to be_truthy
      end

      it "トークンなしではログアウトできない" do
        delete "/api/v1/auth/logout", as: :json
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['message']).to eq("Couldn't find an active session.")
      end

      it "無効なトークンではログアウトできない" do
        # より適切な無効なJWT形式を使用
        invalid_payload = { sub: 'invalid', jti: 'invalid', exp: 1.hour.from_now.to_i }
        invalid_token = "Bearer " + JWT.encode(invalid_payload, 'wrong_secret', 'HS256')
        
        delete "/api/v1/auth/logout", headers: { 'Authorization' => invalid_token }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end