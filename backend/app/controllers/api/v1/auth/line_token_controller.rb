class Api::V1::Auth::LineTokenController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :exchange ]

  def exchange
    unless params[:code].present? && params[:nonce].present? && params[:redirect_uri].present?
      return render json: {
        error: {
          code: "invalid_request",
          message: "code, nonce, redirect_uriが必要です"
        }
      }, status: :bad_request
    end

    # 1. 認可コードをIDトークンに交換
    token_response = LineTokenExchangeService.exchange_code_for_token(
      code: params[:code],
      redirect_uri: params[:redirect_uri]
    )

    # 2. 既存のLineAuthServiceでIDトークン検証＆ユーザー作成/ログイン
    # session_idは渡さない（セッションレス）
    result = LineAuthService.authenticate_with_id_token(
      id_token: token_response[:id_token],
      nonce: params[:nonce]
    )

    user = result[:user]
    line_account = result[:line_account]

    # 3. JWT発行
    token = generate_jwt_token(user)

    render json: {
      token: token,
      user: user_response(user),
      lineAccount: line_account_response(line_account)
    }, status: :ok
  rescue LineTokenExchangeService::ExchangeError => e
    Rails.logger.error "LINEトークン交換エラー: #{e.message}"
    render json: {
      error: {
        code: "token_exchange_failed",
        message: e.message
      }
    }, status: :unauthorized
  rescue LineAuthService::AuthenticationError => e
    Rails.logger.error "LINE認証エラー: #{e.message}"
    error_code = if e.message.include?("Nonce")
      "nonce_mismatch"
    else
      "invalid_token"
    end
    render json: {
      error: {
        code: error_code,
        message: e.message
      }
    }, status: :unauthorized
  end

  def exchange_link
    unless params[:code].present? && params[:nonce].present? && params[:redirect_uri].present?
      return render json: {
        error: {
          code: "invalid_request",
          message: "code, nonce, redirect_uriが必要です"
        }
      }, status: :bad_request
    end

    # 1. 認可コードをIDトークンに交換
    token_response = LineTokenExchangeService.exchange_code_for_token(
      code: params[:code],
      redirect_uri: params[:redirect_uri]
    )

    # 2. 既存ユーザーにLINEアカウントを紐付け
    result = LineAuthService.link_existing_user(
      user: current_user,
      id_token: token_response[:id_token],
      nonce: params[:nonce]
    )

    user = result[:user]
    line_account = result[:line_account]

    # 3. 新しいJWT発行
    token = generate_jwt_token(user)

    render json: {
      token: token,
      user: user_response(user),
      lineAccount: line_account_response(line_account),
      message: "LINE account linked successfully"
    }, status: :ok
  rescue LineTokenExchangeService::ExchangeError => e
    Rails.logger.error "LINEトークン交換エラー: #{e.message}"
    render json: {
      error: {
        code: "token_exchange_failed",
        message: e.message
      }
    }, status: :unauthorized
  rescue LineAuthService::AuthenticationError => e
    Rails.logger.error "LINE連携エラー: #{e.message}"

    if e.message.include?("already linked to another user")
      render json: {
        error: {
          code: "already_linked",
          message: "このLINEアカウントは既に他のユーザーに連携されています"
        }
      }, status: :conflict
    else
      error_code = e.message.include?("Nonce") ? "nonce_mismatch" : "invalid_token"
      render json: {
        error: {
          code: error_code,
          message: e.message
        }
      }, status: :unauthorized
    end
  end

  private

  def generate_jwt_token(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  rescue => e
    Rails.logger.error "JWT generation failed: #{e.message}"
    raise LineAuthService::AuthenticationError, "Failed to generate authentication token"
  end

  def user_response(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      provider: user.provider,
      confirmed: user_confirmed?(user)
    }
  end

  def line_account_response(line_account)
    {
      id: line_account.id,
      lineUserId: line_account.line_user_id,
      displayName: line_account.line_display_name,
      pictureUrl: line_account.line_picture_url,
      linkedAt: line_account.linked_at&.iso8601,
      linked: line_account.linked?
    }
  end

  def user_confirmed?(user)
    if ENV["CONFIRMABLE_ENABLED"] == "true"
      user.confirmed_at.present?
    else
      true
    end
  end
end
