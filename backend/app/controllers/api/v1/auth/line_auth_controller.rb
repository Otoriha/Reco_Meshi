class Api::V1::Auth::LineAuthController < ApplicationController
  before_action :authenticate_user!, only: [:line_link, :line_profile]
  before_action :validate_line_auth_params, only: [:line_login, :line_link]

  def line_login
    result = LineAuthService.authenticate_with_id_token(
      id_token: params[:idToken],
      nonce: params[:nonce]
    )

    user = result[:user]
    line_account = result[:line_account]

    # Generate JWT token using existing devise-jwt mechanism
    token = generate_jwt_token(user)

    render json: {
      token: token,
      user: user_response(user),
      lineAccount: line_account_response(line_account)
    }, status: :ok
  rescue LineAuthService::AuthenticationError => e
    render_auth_error(e.message)
  end

  def line_link
    result = LineAuthService.link_existing_user(
      user: current_user,
      id_token: params[:idToken],
      nonce: params[:nonce]
    )

    line_account = result[:line_account]

    render json: {
      message: 'LINE account linked successfully',
      lineAccount: line_account_response(line_account)
    }, status: :ok
  rescue LineAuthService::AuthenticationError => e
    if e.message.include?('already linked to another user')
      render json: {
        error: {
          code: 'already_linked',
          message: 'このLINEアカウントは既に他のユーザーに連携されています'
        }
      }, status: :conflict
    else
      render_auth_error(e.message)
    end
  end

  def line_profile
    line_account = current_user.line_account

    unless line_account
      return render json: {
        error: {
          code: 'line_account_not_found',
          message: 'LINEアカウントが連携されていません'
        }
      }, status: :not_found
    end

    render json: {
      lineAccount: line_account_response(line_account),
      user: user_response(current_user)
    }, status: :ok
  end

  def generate_nonce
    nonce = NonceStore.generate_and_store(session.id)
    render json: { nonce: nonce }, status: :ok
  end

  private

  def validate_line_auth_params
    unless params[:idToken].present? && params[:nonce].present?
      render json: {
        error: {
          code: 'invalid_request',
          message: 'idTokenとnonceが必要です'
        }
      }, status: :bad_request and return
    end
  end

  def generate_jwt_token(user)
    # Use existing devise-jwt mechanism
    # This assumes Warden::JWTAuth::UserEncoder is available
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  rescue => e
    Rails.logger.error "JWT generation failed: #{e.message}"
    raise LineAuthService::AuthenticationError, 'Failed to generate authentication token'
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
    if ENV['CONFIRMABLE_ENABLED'] == 'true'
      user.confirmed_at.present?
    else
      true
    end
  end

  def render_auth_error(message)
    error_code = case message
                 when /expired/i
                   'expired_token'
                 when /nonce/i
                   'nonce_mismatch'
                 when /audience/i, /aud/i
                   'aud_mismatch'
                 else
                   'invalid_token'
                 end

    render json: {
      error: {
        code: error_code,
        message: message
      }
    }, status: :unauthorized
  end
end