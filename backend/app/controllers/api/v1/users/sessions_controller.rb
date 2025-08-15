class Api::V1::Users::SessionsController < Devise::SessionsController
  protect_from_forgery with: :null_session if respond_to?(:protect_from_forgery)
  respond_to :json
  wrap_parameters false

  # ApplicationControllerのauthenticate_user!をスキップ（ログイン時は認証不要）
  skip_before_action :authenticate_user!, only: [:create, :destroy]

  before_action :normalize_devise_param_keys, only: [:create]

  # カスタム認証（devise-jwtのdispatchは sign_in 呼び出しで発火）
  def create
    self.resource = User.find_for_database_authentication(email: sign_in_params[:email])

    if resource&.valid_password?(sign_in_params[:password])
      if !resource.respond_to?(:confirmed?) || resource.confirmed?
        # APIモードではセッションを書かない
        sign_in(resource_name, resource, store: false)
        respond_with(resource)
      else
        render json: { error: 'You have to confirm your email address' }, status: :unauthorized
      end
    else
      render json: { error: 'Invalid Email or password' }, status: :unauthorized
    end
  end

  private

  # テスト/クライアント互換のため、params[:user] を Devise の resource_name にマップ
  def normalize_devise_param_keys
    key = resource_name
    if params[:user].is_a?(ActionController::Parameters) && params[key].blank?
      params[key] = params[:user]
    end
  end

  # Deviseのサインインパラメータを :user からも受け取れるようにする
  def sign_in_params
    source = params[resource_name] || params[:user] || ActionController::Parameters.new
    source.permit(:email, :password)
  end

  def respond_with(resource, _opts = {})
    render json: {
      status: { code: 200, message: 'Logged in successfully.' },
      data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  def respond_to_on_destroy
    if request.headers['Authorization'].present?
      render json: {
        status: 200,
        message: "Logged out successfully."
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end
end