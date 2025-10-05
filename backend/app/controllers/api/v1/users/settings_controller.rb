class Api::V1::Users::SettingsController < ApplicationController
  before_action :authenticate_user!

  # GET /api/v1/users/settings
  def show
    setting = current_user.setting
    render json: {
      default_servings: setting.default_servings,
      recipe_difficulty: setting.recipe_difficulty,
      cooking_time: setting.cooking_time,
      shopping_frequency: setting.shopping_frequency
    }
  end

  # PATCH /api/v1/users/settings
  def update
    setting = current_user.setting
    if setting.update(settings_params)
      render json: { message: "設定を保存しました" }
    else
      render json: { errors: setting.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:settings).permit(
      :default_servings,
      :recipe_difficulty,
      :cooking_time,
      :shopping_frequency
    )
  end
end
