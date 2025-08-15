class Api::V1::Users::RefreshController < ApplicationController
  before_action :authenticate_user!

  def create
    # 現在のJWTトークンからjtiを取得
    current_jwt = request.headers['Authorization'].to_s.split(' ').last
    payload = JWT.decode(current_jwt, nil, false).first
    
    # 使用したトークンをブラックリストに追加（他端末のトークンは維持）
    JwtDenylist.create!(jti: payload['jti'], exp: Time.at(payload['exp']))
    
    # 新しいJWTトークンを発行（devise-jwtが自動でAuthorizationヘッダに設定）
    sign_in(:user, current_user, store: false)
    
    render json: {
      status: { code: 200, message: 'Token refreshed successfully.' }
    }, status: :ok
  rescue JWT::DecodeError => e
    render json: {
      status: { code: 401, message: 'Invalid token.' }
    }, status: :unauthorized
  rescue StandardError => e
    render json: {
      status: { code: 500, message: 'Token refresh failed.' }
    }, status: :internal_server_error
  end
end