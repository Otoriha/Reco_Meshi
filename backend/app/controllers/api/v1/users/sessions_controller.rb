class Api::V1::Users::SessionsController < Devise::SessionsController
  protect_from_forgery with: :null_session if respond_to?(:protect_from_forgery)
  respond_to :json
  wrap_parameters false

  # ApplicationControllerのauthenticate_user!をスキップ
  # - ログイン時は認証不要
  # - ログアウトはトークンの有無/妥当性で応答を制御するため認証不要
  skip_before_action :authenticate_user!, only: [ :create, :destroy ]

  before_action :normalize_devise_param_keys, only: [ :create ]

  # カスタム認証（devise-jwtのdispatchは sign_in 呼び出しで発火）
  def create
    self.resource = User.find_for_database_authentication(email: sign_in_params[:email])

    if resource&.valid_password?(sign_in_params[:password])
      # CONFIRMABLE_ENABLED が有効な場合は confirmed_at を厳密に確認
      if ENV["CONFIRMABLE_ENABLED"] == "true" && !resource.confirmed_at.present?
        render json: { error: "メールアドレスの確認が必要です" }, status: :unauthorized
        return
      end

      # APIモードではセッションを書かない
      sign_in(resource_name, resource, store: false)
      respond_with(resource)
    else
      render json: { error: "メールアドレスまたはパスワードが正しくありません" }, status: :unauthorized
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
      status: { code: 200, message: "ログインしました。" },
      data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  def respond_to_on_destroy
    token = request.headers["Authorization"].to_s.split(" ").last

    if token.blank?
      render json: {
        status: 401,
        message: "アクティブなセッションが見つかりません。"
      }, status: :unauthorized
      return
    end

    # トークン署名の妥当性のみ確認（Wardenミドルウェアでのrevocationを無効化したためここで完結）
    begin
      JWT.decode(
        token,
        ENV.fetch("DEVISE_JWT_SECRET_KEY", Rails.application.secret_key_base),
        true,
        { algorithm: "HS256" }
      )

      # ログアウト要求に使用したトークンをブラックリストに追加
      begin
        payload = JWT.decode(token, nil, false).first
        JwtDenylist.create!(jti: payload["jti"], exp: Time.at(payload["exp"])) if payload["jti"] && payload["exp"]
      rescue StandardError
        # 失敗時はブラックリスト登録をスキップ（応答は成功でよい）
      end

      render json: {
        status: 200,
        message: "ログアウトしました。"
      }, status: :ok
    rescue JWT::DecodeError
      render json: {
        status: 401,
        message: "無効なトークンです。"
      }, status: :unauthorized
    end
  end
end
