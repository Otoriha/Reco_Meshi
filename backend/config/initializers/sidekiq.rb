require "sidekiq"

redis_url = ENV["SIDEKIQ_REDIS_URL"] || ENV["REDIS_URL"] || "redis://localhost:6379/1"
redis_config = {
  url: redis_url,
  network_timeout: 5
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

