class ApplicationController < ActionController::API
  # APIモードのため、protect_from_forgeryを含めない
  # Deviseコントローラー用の設定
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
