class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  
  # Disable parameter wrapping globally
  wrap_parameters false
  
  # APIモードのため、protect_from_forgeryを含めない
  # Deviseコントローラー用の設定
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # 未確認ユーザーのアクセス制御（必要に応じて各コントローラでskip可能）
  def ensure_confirmed_user!
    return if !current_user.respond_to?(:confirmed?) || current_user.confirmed?

    render json: { error: 'You have to confirm your email address' }, status: :forbidden
  end

  private

  def not_found
    render json: { error: 'リソースが見つかりません' }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  # DeviseのJWTで認証メソッドが正しく読み込まれない場合の手動実装
  def authenticate_user!
    return if current_user

    render json: { error: 'ログインが必要です' }, status: :unauthorized
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = nil
    token = request.headers['Authorization']&.sub(/^Bearer /, '')
    
    if token.present?
      begin
        # devise-jwtの設定に合わせた復号化
        secret_key = ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.secret_key_base)
        payload = JWT.decode(token, secret_key, true, { algorithm: 'HS256' }).first
        @current_user = User.find(payload['sub']) if payload['sub']
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound => e
        @current_user = nil
      end
    end

    @current_user
  end
end
