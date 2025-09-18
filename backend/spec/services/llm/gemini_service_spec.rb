require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Llm::GeminiService do
  let(:mock_connection) { double('Faraday::Connection') }
  let(:service) { described_class.new(connection: mock_connection) }
  let(:messages) { { system: 'You are a chef', user: 'Create a recipe' } }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    Rails.application.config.x.llm = {
      provider: 'gemini',
      timeout_ms: 15000,
      max_retries: 3,
      temperature: 0.7,
      max_tokens: 1000
    }

    allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return('test-api-key')
    allow(ENV).to receive(:fetch).with('GEMINI_MODEL', 'gemini-1.5-flash').and_return('gemini-1.5-flash')
  end

  describe '#initialize' do
    context 'when API key is missing' do
      before do
        allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return(nil)
      end

      it 'raises an error' do
        expect {
          described_class.new
        }.to raise_error('Gemini API key is not configured')
      end
    end

    context 'when API key is present' do
      it 'initializes successfully' do
        expect {
          described_class.new(connection: mock_connection)
        }.not_to raise_error
      end
    end
  end

  describe '#generate' do
    let(:mock_response_body) do
      {
        'candidates' => [
          {
            'content' => {
              'parts' => [
                {
                  'text' => '{"title": "Test Recipe", "time": "15 minutes"}'
                }
              ]
            }
          }
        ],
        'usageMetadata' => { 'totalTokenCount' => 120 }
      }
    end

    let(:mock_response) do
      double('Response', status: 200, body: mock_response_body)
    end

    before do
      allow(mock_connection).to receive(:post).and_return(mock_response)
    end

    context 'with text response format' do
      it 'returns a Result with text content' do
        result = service.generate(messages: messages, response_format: :text)

        expect(result).to be_a(Llm::Result)
        expect(result.text).to eq('{"title": "Test Recipe", "time": "15 minutes"}')
        expect(result.provider).to eq('gemini')
        expect(result.model).to eq('gemini-1.5-flash')
        expect(result.usage).to eq({ 'totalTokenCount' => 120 })
      end

      it 'calls Gemini API with correct parameters' do
        expected_body = {
          contents: [
            {
              role: 'user',
              parts: [ { text: "You are a chef\n\nCreate a recipe" } ]
            }
          ],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 1000
          }
        }

        expect(mock_connection).to receive(:post).with(
          '/v1beta/models/gemini-1.5-flash:generateContent?key=test-api-key',
          expected_body
        )

        service.generate(messages: messages, response_format: :text)
      end
    end

    context 'with JSON response format' do
      it 'calls Gemini API with JSON MIME type' do
        expected_body = {
          contents: [
            {
              role: 'user',
              parts: [ { text: "You are a chef\n\nCreate a recipe" } ]
            }
          ],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 1000,
            response_mime_type: 'application/json'
          }
        }

        expect(mock_connection).to receive(:post).with(
          '/v1beta/models/gemini-1.5-flash:generateContent?key=test-api-key',
          expected_body
        )

        service.generate(messages: messages, response_format: :json)
      end

      it 'parses JSON response' do
        result = service.generate(messages: messages, response_format: :json)

        expect(result.raw_json).to eq({ 'title' => 'Test Recipe', 'time' => '15 minutes' })
      end

      context 'when JSON parsing fails' do
        let(:invalid_json_response_body) do
          {
            'candidates' => [
              {
                'content' => {
                  'parts' => [
                    {
                      'text' => 'Invalid JSON content'
                    }
                  ]
                }
              }
            ],
            'usageMetadata' => { 'totalTokenCount' => 50 }
          }
        end

        let(:invalid_mock_response) do
          double('Response', status: 200, body: invalid_json_response_body)
        end

        before do
          allow(mock_connection).to receive(:post).and_return(invalid_mock_response)
        end

        it 'leaves raw_json as nil' do
          result = service.generate(messages: messages, response_format: :json)

          expect(result.text).to eq('Invalid JSON content')
          expect(result.raw_json).to be_nil
        end
      end
    end

    context 'when API returns error status' do
      let(:error_response) do
        double('Response', status: 400, body: { 'error' => 'Bad request' })
      end

      before do
        allow(mock_connection).to receive(:post).and_return(error_response)
      end

      it 'raises an error' do
        expect {
          service.generate(messages: messages)
        }.to raise_error(/Gemini API error: 400/)
      end
    end

    it 'instruments the request' do
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        'llm.request',
        hash_including(
          provider: 'gemini',
          model: 'gemini-1.5-flash',
          tokens: { 'totalTokenCount' => 120 }
        )
      )

      service.generate(messages: messages)
    end
  end

  describe '#build_prompt' do
    it 'combines system and user messages' do
      service_instance = described_class.new(connection: mock_connection)
      messages = { system: 'System prompt', user: 'User prompt' }

      result = service_instance.send(:build_prompt, messages)

      expect(result).to eq('System prompt

User prompt')
    end

    it 'handles missing system message' do
      service_instance = described_class.new(connection: mock_connection)
      messages = { user: 'User prompt' }

      result = service_instance.send(:build_prompt, messages)

      expect(result).to eq('User prompt')
    end
  end

  describe '#extract_text' do
    let(:service_instance) { described_class.new(connection: mock_connection) }

    context 'with valid response body' do
      let(:body) do
        {
          'candidates' => [
            {
              'content' => {
                'parts' => [
                  { 'text' => 'Generated text content' }
                ]
              }
            }
          ]
        }
      end

      it 'extracts text from response' do
        result = service_instance.send(:extract_text, body)
        expect(result).to eq('Generated text content')
      end
    end

    context 'with empty or malformed response' do
      it 'returns empty string for nil candidates' do
        result = service_instance.send(:extract_text, { 'candidates' => nil })
        expect(result).to eq('')
      end

      it 'returns empty string for missing text' do
        body = {
          'candidates' => [
            {
              'content' => {
                'parts' => [ {} ]
              }
            }
          ]
        }
        result = service_instance.send(:extract_text, body)
        expect(result).to eq('')
      end
    end
  end
end
