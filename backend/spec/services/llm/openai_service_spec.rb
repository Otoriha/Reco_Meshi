require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Llm::OpenaiService do
  let(:mock_client) { double('OpenAI::Client') }
  let(:service) { described_class.new(client: mock_client) }
  let(:messages) { { system: 'You are a chef', user: 'Create a recipe' } }

  before do
    Rails.application.config.x.llm = {
      provider: 'openai',
      timeout_ms: 10000,
      max_retries: 3,
      temperature: 0.7,
      max_tokens: 1000,
      reasoning_effort: 'low',
      verbosity: 'low'
    }
    
    allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
    allow(ENV).to receive(:fetch).with('OPENAI_MODEL', 'gpt-4o-mini').and_return('gpt-4o-mini')
  end

  describe '#initialize' do
    context 'when API key is missing' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      end

      it 'raises an error' do
        expect {
          described_class.new
        }.to raise_error('OpenAI API key is not configured')
      end
    end

    context 'when API key is present' do
      it 'initializes successfully' do
        expect {
          described_class.new(client: mock_client)
        }.not_to raise_error
      end
    end
  end

  describe '#generate' do
    let(:mock_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => '{"title": "Test Recipe", "time": "15 minutes"}'
            }
          }
        ],
        'usage' => { 'total_tokens' => 150 }
      }
    end

    before do
      allow(mock_client).to receive(:chat).and_return(mock_response)
    end

    context 'with text response format' do
      it 'returns a Result with text content' do
        result = service.generate(messages: messages, response_format: :text)
        
        expect(result).to be_a(Llm::Result)
        expect(result.text).to eq('{"title": "Test Recipe", "time": "15 minutes"}')
        expect(result.provider).to eq('openai')
        expect(result.model).to eq('gpt-4o-mini')
        expect(result.usage).to eq({ 'total_tokens' => 150 })
      end

      it 'calls OpenAI API with correct parameters' do
        expect(mock_client).to receive(:chat).with(
          parameters: {
            model: 'gpt-4o-mini',
            messages: [
              { role: 'system', content: 'You are a chef' },
              { role: 'user', content: 'Create a recipe' }
            ],
            temperature: 0.7,
            max_tokens: 1000
          }
        )

        service.generate(messages: messages, response_format: :text)
      end
    end

    context 'with JSON response format' do
      it 'calls OpenAI API with JSON response format' do
        expect(mock_client).to receive(:chat).with(
          parameters: {
            model: 'gpt-4o-mini',
            messages: [
              { role: 'system', content: 'You are a chef' },
              { role: 'user', content: 'Create a recipe' }
            ],
            temperature: 0.7,
            max_tokens: 1000,
            response_format: { type: 'json_object' }
          }
        )

        service.generate(messages: messages, response_format: :json)
      end

      it 'parses JSON response' do
        result = service.generate(messages: messages, response_format: :json)
        
        expect(result.raw_json).to eq({ 'title' => 'Test Recipe', 'time' => '15 minutes' })
      end

      context 'when JSON parsing fails' do
        let(:invalid_json_response) do
          {
            'choices' => [
              {
                'message' => {
                  'content' => 'Invalid JSON content'
                }
              }
            ],
            'usage' => { 'total_tokens' => 50 }
          }
        end

        before do
          allow(mock_client).to receive(:chat).and_return(invalid_json_response)
        end

        it 'leaves raw_json as nil' do
          result = service.generate(messages: messages, response_format: :json)
          
          expect(result.text).to eq('Invalid JSON content')
          expect(result.raw_json).to be_nil
        end
      end
    end

    context 'when API call fails' do
      before do
        allow(mock_client).to receive(:chat).and_raise(StandardError.new('API Error'))
      end

      it 'raises the error after retries' do
        expect {
          service.generate(messages: messages)
        }.to raise_error('API Error')
      end
    end

    it 'instruments the request' do
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'llm.request',
        hash_including(
          provider: 'openai',
          model: 'gpt-4o-mini',
          tokens: { 'total_tokens' => 150 }
        )
      )

      service.generate(messages: messages)
    end
  end

  describe '#to_openai_messages' do
    it 'converts messages hash to OpenAI format' do
      service_instance = described_class.new(client: mock_client)
      messages = { system: 'System prompt', user: 'User prompt' }
      
      result = service_instance.send(:to_openai_messages, messages)
      
      expect(result).to eq([
        { role: 'system', content: 'System prompt' },
        { role: 'user', content: 'User prompt' }
      ])
    end

    it 'handles empty system message' do
      service_instance = described_class.new(client: mock_client)
      messages = { user: 'User prompt' }
      
      result = service_instance.send(:to_openai_messages, messages)
      
      expect(result).to eq([
        { role: 'user', content: 'User prompt' }
      ])
    end
  end
end
    context 'when using a GPT-5 model' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_MODEL', 'gpt-4o-mini').and_return('gpt-5-nano-2025-08-07')
      end

      it 'includes reasoning_effort and verbosity parameters' do
        expect(mock_client).to receive(:chat).with(
          parameters: hash_including(
            model: 'gpt-5-nano-2025-08-07',
            max_tokens: 1000,
            temperature: 0.7,
            reasoning_effort: 'low',
            verbosity: 'low'
          )
        ).and_return(mock_response)

        service.generate(messages: messages)
      end

      it 'logs a warning about GPT-5 params' do
        allow(mock_client).to receive(:chat).and_return(mock_response)
        expect(Rails.logger).to receive(:warn).with('[LLM] Using GPT-5 model; applying reasoning_effort/verbosity')
        service.generate(messages: messages)
      end
    end
