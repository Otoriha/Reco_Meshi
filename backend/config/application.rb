require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine" # ActionCable未使用のためコメントアウト
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Add session middleware for Sidekiq Web UI in development
    if Rails.env.development?
      config.session_store :cookie_store, key: "_recomeshi_session"
      config.middleware.use ActionDispatch::Cookies
      config.middleware.use ActionDispatch::Session::CookieStore, config.session_options
    end

    # Default Active Job adapter (fallback); env-specific files will override
    config.active_job.queue_adapter = :inline

    # Vision API設定の集中管理
    config.x.vision.label_min_score = ENV.fetch("VISION_LABEL_MIN_SCORE", "0.4").to_f.clamp(0.0, 1.0)
    config.x.vision.object_min_score = ENV.fetch("VISION_OBJECT_MIN_SCORE", "0.4").to_f.clamp(0.0, 1.0)
    config.x.vision.ingredient_threshold = ENV.fetch("VISION_INGREDIENT_THRESHOLD", "0.5").to_f.clamp(0.0, 1.0)
    config.x.vision.max_results = ENV.fetch("VISION_MAX_RESULTS", "50").to_i.clamp(1, 100)

    # Vision機能フラグ
    config.x.vision.enable_crop_reeval = ENV.fetch("VISION_ENABLE_CROP_REEVAL", "false") == "true"
    config.x.vision.enable_crop_hints = ENV.fetch("VISION_ENABLE_CROP_HINTS", "false") == "true"
    config.x.vision.enable_preprocess = ENV.fetch("VISION_ENABLE_PREPROCESS", "false") == "true"

    # Visionコスト制御
    config.x.vision.max_crops = ENV.fetch("VISION_MAX_CROPS", "10").to_i.clamp(0, 20)
    config.x.vision.api_max_calls = ENV.fetch("VISION_API_MAX_CALLS_PER_IMAGE", "15").to_i.clamp(1, 30)

    # 起動時に設定値をログ出力（ログが利用可能な場合のみ）
    config.after_initialize do
      if Rails.logger
        Rails.logger.info "Vision API Configuration: " +
          "label_min=#{config.x.vision.label_min_score}, " +
          "object_min=#{config.x.vision.object_min_score}, " +
          "ingredient_threshold=#{config.x.vision.ingredient_threshold}, " +
          "max_results=#{config.x.vision.max_results}, " +
          "crop_reeval=#{config.x.vision.enable_crop_reeval}, " +
          "max_crops=#{config.x.vision.max_crops}, " +
          "api_max_calls=#{config.x.vision.api_max_calls}"
      end
    end
  end
end
