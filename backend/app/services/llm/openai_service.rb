require 'openai'
require 'json'

module Llm
  class OpenaiService < BaseService
    def initialize(client: nil)
      api_key = ENV['OPENAI_API_KEY']
      raise 'OpenAI API key is not configured' if api_key.nil? || api_key.empty?

      timeout_s = (config_value(:timeout_ms).to_i / 1000.0)
      @client = client || OpenAI::Client.new(access_token: api_key, request_timeout: timeout_s)
    end

    def generate(messages:, response_format: :text, temperature: nil, max_tokens: nil)
      model = ENV.fetch('OPENAI_MODEL', 'gpt-4o-mini')
      temperature ||= config_value(:temperature).to_f
      max_tokens ||= config_value(:max_tokens).to_i
      
      # GPT-5 models use different parameter names and have restrictions
      if model.include?('gpt-5')
        # Use max_completion_tokens for GPT-5 models
        token_param = :max_completion_tokens
        # GPT-5 models don't support custom temperature, use default
        use_temperature = false
      else
        # Standard models use max_tokens and support temperature
        token_param = :max_tokens  
        use_temperature = true
      end

      rfmt = response_format == :json ? { type: 'json_object' } : nil

      # Build parameters based on model capabilities
      params = {
        model: model,
        messages: to_openai_messages(messages),
        token_param => max_tokens,
        response_format: rfmt
      }.compact
      
      # Add temperature only for models that support it
      if use_temperature
        params[:temperature] = temperature
      end

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = with_retries(max_retries: config_value(:max_retries).to_i, base_delay: 0.5) do
        @client.chat(parameters: params)
      end
      duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0).round

      content = response.dig('choices', 0, 'message', 'content').to_s
      usage = response['usage']

      ActiveSupport::Notifications.instrument('llm.request', {
        provider: 'openai',
        model: model,
        duration: duration,
        tokens: usage
      })

      result = Llm::Result.new(text: content, provider: 'openai', model: model, usage: usage)
      if response_format == :json
        begin
          result.raw_json = JSON.parse(content)
        rescue JSON::ParserError
          # leave raw_json nil, allow caller to fallback
        end
      end
      result
    end

    private

    def to_openai_messages(msgs)
      sys = msgs[:system].to_s
      usr = msgs[:user].to_s
      arr = []
      arr << { role: 'system', content: sys } unless sys.empty?
      arr << { role: 'user', content: usr } unless usr.empty?
      arr
    end

    def config_value(key)
      cfg = Rails.application.config.x.llm
      cfg.is_a?(Hash) ? cfg[key] : cfg.public_send(key)
    end
  end
end
