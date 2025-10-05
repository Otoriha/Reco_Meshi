class Api::V1::Users::PasswordsController < ApplicationController
  before_action :authenticate_user!

  # POST /api/v1/users/change_password
  def create
    unless current_user.valid_password?(password_params[:current_password])
      render json: { error: "現在のパスワードが正しくありません" }, status: :unauthorized
      return
    end

    if current_user.update(
      password: password_params[:new_password],
      password_confirmation: password_params[:new_password_confirmation]
    )
      render json: { message: "パスワードを変更しました。セキュリティのため再ログインしてください" }
    else
      render json: { errors: current_user.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:password).permit(:current_password, :new_password, :new_password_confirmation)
  end
end
