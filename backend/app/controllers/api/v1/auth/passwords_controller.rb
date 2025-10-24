class Api::V1::Auth::PasswordsController < Devise::PasswordsController
  respond_to :json
  skip_before_action :authenticate_user!

  # POST /api/v1/auth/password
  # Request a password reset email
  def create
    self.resource = resource_class.send_reset_password_instructions(
      resource_params
    )

    # paranoid = true: return same success message regardless of email existence
    if successfully_sent?(resource)
      render json: {
        message: "パスワードリセットメールを送信しました。メールをご確認ください"
      }, status: :ok
    else
      # Only return errors for validation issues (e.g., invalid email format)
      render json: {
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/auth/password
  # Reset password with token
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      render json: {
        message: "パスワードを変更しました。新しいパスワードでログインしてください"
      }, status: :ok
    else
      render json: {
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  protected

  def resource_params
    params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
  end
end
