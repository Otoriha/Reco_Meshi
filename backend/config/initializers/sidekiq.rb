require "sidekiq"

redis_url = ENV["SIDEKIQ_REDIS_URL"] || ENV["REDIS_URL"] || "redis://localhost:6379/1"
redis_config = {
  url: redis_url,
  network_timeout: 5
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  # デフォルトのリトライ回数を制限（無限リトライ防止）
  config.default_job_options = { retry: 3 }

  # Production環境でのキュー設定
  if Rails.env.production?
    config.queues = %w[reco_meshi_production_default reco_meshi_production_mailers]
  else
    config.queues = %w[default mailers]
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
