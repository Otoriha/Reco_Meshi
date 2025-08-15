class Api::V1::Users::RegistrationsController < Devise::RegistrationsController
  protect_from_forgery with: :null_session if respond_to?(:protect_from_forgery)
  respond_to :json
  wrap_parameters false

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

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end