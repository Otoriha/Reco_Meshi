class Api::V1::Users::EmailsController < ApplicationController
  before_action :authenticate_user!

  # POST /api/v1/users/change_email
  def create
    unless current_user.valid_password?(email_params[:current_password])
      render json: { error: "パスワードが正しくありません" }, status: :unauthorized
      return
    end

    if current_user.update(email: email_params[:email])
      render json: { message: "メールアドレスを変更しました。確認メールを送信しました" }
    else
      render json: { errors: current_user.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def email_params
    params.require(:email_change).permit(:email, :current_password)
  end
end
