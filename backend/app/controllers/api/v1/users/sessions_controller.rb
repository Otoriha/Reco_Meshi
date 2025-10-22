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
    email = sign_in_params[:email]
    password = sign_in_params[:password]

    Rails.logger.debug "[SessionsController] Login attempt - Email: #{email}"

    self.resource = User.find_for_database_authentication(email: email)

    if resource.nil?
      Rails.logger.warn "[SessionsController] User not found - Email: #{email}"
      render json: { error: "メールアドレスまたはパスワードが正しくありません" }, status: :unauthorized
      return
    end

    Rails.logger.debug "[SessionsController] User found - ID: #{resource.id}"

    if resource.valid_password?(password)
      Rails.logger.debug "[SessionsController] Password valid"

      # CONFIRMABLE_ENABLED が有効な場合は confirmed_at を厳密に確認
      if ENV["CONFIRMABLE_ENABLED"] == "true" && !resource.confirmed_at.present?
        Rails.logger.warn "[SessionsController] Email not confirmed"
        render json: { error: "メールアドレスの確認が必要です" }, status: :unauthorized
        return
      end

      Rails.logger.debug "[SessionsController] Signing in user"
      begin
        # APIモードではセッションを書かない
        sign_in(resource_name, resource, store: false)
        Rails.logger.info "[SessionsController] Sign in successful"
        respond_with(resource)
      rescue => e
        Rails.logger.error "[SessionsController] Sign in error: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "ログイン処理中にエラーが発生しました" }, status: :internal_server_error
      end
    else
      Rails.logger.warn "[SessionsController] Password invalid"
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
    begin
      Rails.logger.info "[SessionsController] respond_with called for user #{resource.id}"
      serialized = UserSerializer.new(resource).serializable_hash
      Rails.logger.info "[SessionsController] Serialization successful"

      render json: {
        status: { code: 200, message: "ログインしました。" },
        data: serialized[:data][:attributes]
      }, status: :ok
    rescue => e
      Rails.logger.error "[SessionsController] respond_with error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "レスポンス生成エラー: #{e.message}" }, status: :internal_server_error
    end
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
