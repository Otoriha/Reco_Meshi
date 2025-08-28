module Llm
  class Result
    attr_accessor :text, :raw_json, :provider, :model, :usage

    def initialize(text: nil, raw_json: nil, provider: nil, model: nil, usage: nil)
      @text = text
      @raw_json = raw_json
      @provider = provider
      @model = model
      @usage = usage
    end
  end

  class BaseService
    def generate(messages:, response_format: :text, temperature: 0.7, max_tokens: 1000)
      raise NotImplementedError
    end

    protected

    def jittered_sleep(seconds)
      Kernel.sleep(seconds + rand * 0.25)
    end

    def with_retries(max_retries:, base_delay: 0.5)
      attempts = 0
      begin
        return yield
      rescue => e
        attempts += 1
        raise e if attempts > max_retries
        delay = base_delay * (2**(attempts - 1))
        jittered_sleep(delay)
        retry
      end
    end
  end
end

