class Api::V1::Users::ProfilesController < ApplicationController
  before_action :authenticate_user!

  # GET /api/v1/users/profile
  def show
    line_account_data = if current_user.line_account.present?
                          {
                            displayName: current_user.line_account.line_display_name.presence || "",
                            linkedAt: current_user.line_account.linked_at&.iso8601
                          }
    else
                          nil
    end

    render json: {
      name: current_user.name,
      email: current_user.email,
      provider: current_user.provider,
      lineAccount: line_account_data
    }
  end

  # PATCH /api/v1/users/profile
  def update
    if current_user.update(profile_params)
      render json: { message: "プロフィールを更新しました" }
    else
      render json: { errors: current_user.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:name)
  end
end
