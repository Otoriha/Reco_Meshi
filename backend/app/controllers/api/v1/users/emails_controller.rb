class Api::V1::Users::EmailsController < ApplicationController
  before_action :authenticate_user!

  # POST /api/v1/users/change_email
  # Change user's email address (triggers confirmation email via reconfirmable)
  def create
    unless current_user.valid_password?(email_params[:current_password])
      render json: { error: "パスワードが正しくありません" }, status: :unauthorized
      return
    end

    # Use Devise's reconfirmable mechanism by updating the email attribute
    # This automatically sets unconfirmed_email and generates a confirmation token
    if current_user.update(email: email_params[:email])
      render json: {
        message: "確認メールを送信しました。新しいメールアドレスのメールをご確認ください",
        unconfirmed_email: current_user.unconfirmed_email,
        current_email: current_user.email
      }, status: :ok
    else
      render json: { errors: current_user.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def email_params
    params.require(:email_change).permit(:email, :current_password)
  end
end
