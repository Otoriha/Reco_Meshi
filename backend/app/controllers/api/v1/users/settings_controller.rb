class Api::V1::Users::SettingsController < ApplicationController
  before_action :authenticate_user!

  # GET /api/v1/users/settings
  def show
    setting = current_user.setting
    render json: {
      default_servings: setting.default_servings,
      recipe_difficulty: setting.recipe_difficulty,
      cooking_time: setting.cooking_time,
      shopping_frequency: setting.shopping_frequency,
      inventory_reminder_enabled: setting.inventory_reminder_enabled,
      inventory_reminder_time: format_time(setting.inventory_reminder_time)
    }
  end

  # PATCH /api/v1/users/settings
  def update
    setting = current_user.setting

    # 時刻文字列のパース処理（シンボルキー対応）
    parsed_params = parse_notification_params(settings_params)

    if setting.update(parsed_params)
      render json: { message: "設定を保存しました" }
    else
      render json: { errors: setting.errors.messages }, status: :unprocessable_entity
    end
  rescue InvalidTimeFormatError => e
    render json: {
      success: false,
      error: {
        code: "INVALID_TIME_FORMAT",
        message: e.message
      }
    }, status: :unprocessable_entity
  end

  private

  def settings_params
    params.require(:settings).permit(
      :default_servings,
      :recipe_difficulty,
      :cooking_time,
      :shopping_frequency,
      :inventory_reminder_enabled,
      :inventory_reminder_time
    )
  end

  def format_time(time_obj)
    return nil if time_obj.blank?
    time_obj.strftime("%H:%M")
  end

  def parse_notification_params(params)
    # ActionController::Parametersをシンボルキーのハッシュに変換
    parsed = params.to_h.symbolize_keys

    # inventory_reminder_timeが文字列の場合、厳密な検証とTime型への変換
    if parsed[:inventory_reminder_time].present? && parsed[:inventory_reminder_time].is_a?(String)
      time_string = parsed[:inventory_reminder_time]

      # 厳密なフォーマット検証: HH:MM形式（09:00はOK、9:00はNG）
      unless time_string.match?(/\A([01][0-9]|2[0-3]):[0-5][0-9]\z/)
        raise InvalidTimeFormatError, "時刻はHH:MM形式で入力してください（例: 09:00）"
      end

      # Time型に変換
      parsed_time = Time.zone.parse(time_string)

      # パース失敗時（nilの場合）
      if parsed_time.nil?
        raise InvalidTimeFormatError, "時刻の解析に失敗しました"
      end

      parsed[:inventory_reminder_time] = parsed_time
    end

    parsed
  end

  # カスタム例外クラス
  class InvalidTimeFormatError < StandardError; end
end
