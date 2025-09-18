module Llm
  class Factory
    def self.build(provider: nil)
      cfg = Rails.application.config.x.llm
      provider ||= (cfg.is_a?(Hash) ? cfg[:provider] : cfg&.provider)
      case provider
      when "openai"
        Llm::OpenaiService.new
      when "gemini"
        Llm::GeminiService.new
      else
        raise "Unknown LLM provider: #{provider}"
      end
    end
  end
end
