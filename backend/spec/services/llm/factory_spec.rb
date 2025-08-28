require 'rails_helper'

RSpec.describe Llm::Factory do
  before do
    Rails.application.config.x.llm = {
      provider: 'openai',
      timeout_ms: 15000,
      max_retries: 3,
      temperature: 0.7,
      max_tokens: 1000,
      fallback_provider: 'gemini'
    }
  end

  describe '.build' do
    context 'when provider is openai' do
      it 'returns OpenaiService instance' do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
        service = described_class.build(provider: 'openai')
        expect(service).to be_a(Llm::OpenaiService)
      end
    end

    context 'when provider is gemini' do
      it 'returns GeminiService instance' do
        allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return('test-key')
        service = described_class.build(provider: 'gemini')
        expect(service).to be_a(Llm::GeminiService)
      end
    end

    context 'when provider is not specified' do
      it 'uses default provider from config' do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
        service = described_class.build
        expect(service).to be_a(Llm::OpenaiService)
      end
    end

    context 'when provider is unknown' do
      it 'raises an error' do
        expect {
          described_class.build(provider: 'unknown')
        }.to raise_error('Unknown LLM provider: unknown')
      end
    end
  end
end