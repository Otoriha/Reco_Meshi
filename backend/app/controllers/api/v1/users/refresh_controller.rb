class Api::V1::Users::RefreshController < ApplicationController
  include Devise::Controllers::Helpers

  # ApplicationControllerのauthenticate_user!をskipして独自に実装
  skip_before_action :authenticate_user!
  before_action :authenticate_refresh_token!

  protect_from_forgery with: :null_session if respond_to?(:protect_from_forgery)
  respond_to :json

  def create
    # 現在のJWTトークンからjtiを取得
    current_jwt = request.headers["Authorization"].to_s.split(" ").last
    payload = JWT.decode(current_jwt, nil, false).first

    # 使用したトークンをブラックリストに追加（他端末のトークンは維持）
    JwtDenylist.create!(jti: payload["jti"], exp: Time.at(payload["exp"]))

    # 新しいJWTトークンを発行
    # 1) devise-jwtのdispatchに頼らず、明示的にエンコードしてヘッダ付与
    sign_in(:user, current_user, store: false)
    token, _ = Warden::JWTAuth::UserEncoder.new.call(current_user, :user, nil)
    response.set_header("Authorization", "Bearer #{token}")

    render json: {
      status: { code: 200, message: "Token refreshed successfully." }
    }, status: :ok
  rescue JWT::DecodeError => e
    render json: {
      status: { code: 401, message: "Invalid token." }
    }, status: :unauthorized
  rescue StandardError => e
    render json: {
      status: { code: 500, message: "Token refresh failed." }
    }, status: :internal_server_error
  end

  private

  def authenticate_refresh_token!
    token = request.headers["Authorization"].to_s.split(" ").last

    if token.blank?
      render json: { status: { code: 401, message: "Token required." } }, status: :unauthorized
      return
    end

    begin
      payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY", Rails.application.secret_key_base), true, { algorithm: "HS256" })
      user_id = payload.first["sub"]
      @current_user = User.find(user_id)

      # ブラックリストチェック
      if JwtDenylist.exists?(jti: payload.first["jti"])
        render json: { status: { code: 401, message: "Token has been revoked." } }, status: :unauthorized
        nil
      end
    rescue JWT::DecodeError
      render json: { status: { code: 401, message: "Invalid token." } }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { status: { code: 401, message: "User not found." } }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end
