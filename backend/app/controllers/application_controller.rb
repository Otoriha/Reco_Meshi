class ApplicationController < ActionController::API
  # APIモードのため、protect_from_forgeryを含めない
  # Deviseコントローラー用の設定
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

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
end
