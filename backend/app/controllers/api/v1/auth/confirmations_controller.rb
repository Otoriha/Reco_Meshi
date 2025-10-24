class Api::V1::Auth::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json
  skip_before_action :authenticate_user!

  # GET /api/v1/auth/confirmation?confirmation_token=XXX
  # Confirm user email with token
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      render json: {
        message: "メールアドレスを確認しました。ログインしてください",
        email: resource.email
      }, status: :ok
    else
      render json: {
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/auth/confirmation
  # Resend confirmation email
  def create
    self.resource = resource_class.send_confirmation_instructions(
      resource_params
    )

    # paranoid = true: return same success message regardless of email existence
    if successfully_sent?(resource)
      render json: {
        message: "確認メールを再送信しました"
      }, status: :ok
    else
      # Only return errors for validation issues
      render json: {
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  protected

  def resource_params
    params.require(:user).permit(:email)
  end
end
