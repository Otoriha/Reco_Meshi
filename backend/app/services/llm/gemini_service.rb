require "faraday"
require "faraday/retry"
require "json"

module Llm
  class GeminiService < BaseService
    API_BASE = "https://generativelanguage.googleapis.com".freeze

    def initialize(connection: nil)
      @api_key = ENV["GEMINI_API_KEY"]
      raise "Gemini API key is not configured" if @api_key.nil? || @api_key.empty?

      @model = ENV.fetch("GEMINI_MODEL", "gemini-1.5-flash")
      timeout_s = (config_value(:timeout_ms).to_i / 1000.0)
      max_retries = config_value(:max_retries).to_i

      @conn = connection || Faraday.new(url: API_BASE) do |f|
        f.request :json
        f.request :retry, max: max_retries, interval: 0.5, interval_randomness: 0.5, backoff_factor: 2,
                          retry_statuses: [ 429, 500, 502, 503, 504 ],
                          methods: %i[post get],
                          retry_if: ->(env, _exception) { env.response&.status.to_i >= 500 || env.response&.status == 429 }
        f.response :json, content_type: /\bjson$/
        f.options.timeout = timeout_s
        f.adapter Faraday.default_adapter
      end
    end

    def generate(messages:, response_format: :text, temperature: nil, max_tokens: nil)
      temperature ||= config_value(:temperature).to_f
      max_tokens ||= config_value(:max_tokens).to_i
      prompt = build_prompt(messages)

      body = {
        contents: [
          {
            role: "user",
            parts: [ { text: prompt } ]
          }
        ],
        generationConfig: {
          temperature: temperature,
          maxOutputTokens: max_tokens
        }
      }
      if response_format == :json
        body[:generationConfig][:response_mime_type] = "application/json"
      end

      path = "/v1beta/models/#{@model}:generateContent"
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      resp = @conn.post("#{path}?key=#{@api_key}", body)
      duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0).round

      if resp.status >= 400
        raise "Gemini API error: #{resp.status} #{resp.body}"
      end

      text = extract_text(resp.body)
      usage = resp.body["usageMetadata"]

      ActiveSupport::Notifications.instrument("llm.request", {
        provider: "gemini",
        model: @model,
        duration: duration,
        tokens: usage
      })

      result = Llm::Result.new(text: text, provider: "gemini", model: @model, usage: usage)
      if response_format == :json
        begin
          result.raw_json = JSON.parse(text)
        rescue JSON::ParserError
          # allow caller to fallback to text
        end
      end
      result
    end

    private

    def build_prompt(msgs)
      [ msgs[:system], msgs[:user] ].compact.join("\n\n")
    end

    def extract_text(body)
      candidates = body["candidates"]
      return "" unless candidates && candidates.first
      parts = candidates.first.dig("content", "parts")
      if parts && parts.first && parts.first["text"]
        parts.first["text"]
      else
        ""
      end
    end

    def config_value(key)
      cfg = Rails.application.config.x.llm
      cfg.is_a?(Hash) ? cfg[key] : cfg.public_send(key)
    end
  end
end
