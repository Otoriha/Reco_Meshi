class Api::V1::Users::RegistrationsController < Devise::RegistrationsController
  protect_from_forgery with: :null_session if respond_to?(:protect_from_forgery)
  respond_to :json
  wrap_parameters false

  # ApplicationControllerのauthenticate_user!をスキップ（新規登録時は認証不要）
  skip_before_action :authenticate_user!, only: [:create]

  before_action :normalize_devise_param_keys, only: [:create]

  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  private

  # テスト/クライアント互換のため、params[:user] を Devise の resource_name にマップ
  def normalize_devise_param_keys
    key = resource_name
    if params[:user].is_a?(ActionController::Parameters) && params[key].blank?
      params[key] = params[:user]
    end
  end

  # Deviseのサインアップパラメータを :user からも受け取れるようにする
  def sign_up_params
    source = params[resource_name] || params[:user] || ActionController::Parameters.new
    source.permit(:name, :email, :password, :password_confirmation)
  end

  def respond_with(resource, _opts = {})
  if resource.persisted?
    # APIモードではsign_inではなく、JWTトークンを手動で生成
    token = generate_jwt_token(resource)
    response.set_header('Authorization', "Bearer #{token}")
    
    render json: {
      status: { code: 200, message: 'Signed up successfully.' },
      data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
    }, status: :ok
  else
    render json: {
      status: { message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" }
    }, status: :unprocessable_entity
  end
end

# APIモードでJWTトークンを手動生成するためのヘルパーメソッド
def generate_jwt_token(user)
  payload = user.jwt_payload.merge({
    sub: user.id.to_s,
    jti: SecureRandom.uuid,
    exp: 1.day.from_now.to_i
  })
  
  JWT.encode(payload, ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.secret_key_base), 'HS256')
end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end