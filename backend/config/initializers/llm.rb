Rails.application.config.x.llm = {
  provider: ENV.fetch('LLM_PROVIDER', 'openai'),
  timeout_ms: ENV.fetch('LLM_TIMEOUT_MS', 15_000).to_i,
  max_retries: ENV.fetch('LLM_MAX_RETRIES', 3).to_i,
  temperature: ENV.fetch('LLM_TEMPERATURE', 0.7).to_f,
  max_tokens: ENV.fetch('LLM_MAX_TOKENS', 1_000).to_i,
  fallback_provider: ENV['LLM_FALLBACK_PROVIDER']
}

