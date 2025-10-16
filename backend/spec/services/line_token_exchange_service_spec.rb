require 'rails_helper'

RSpec.describe LineTokenExchangeService do
  let(:service) { described_class.new }
  let(:code) { 'test-authorization-code' }
  let(:redirect_uri) { 'http://localhost:3001/auth/line/callback' }
  let(:id_token) { 'mock-id-token' }
  let(:access_token) { 'mock-access-token' }

  before do
    # 環境変数をモック
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return('test-channel-id')
    allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return('test-channel-secret')
  end

  describe '#exchange_code_for_token' do
    context '正常なレスポンスの場合' do
      let(:success_response_body) do
        {
          'id_token' => id_token,
          'access_token' => access_token,
          'expires_in' => 3600,
          'refresh_token' => 'mock-refresh-token',
          'token_type' => 'Bearer'
        }.to_json
      end

      let(:mock_response) do
        instance_double(Faraday::Response, success?: true, body: success_response_body)
      end

      before do
        allow(Faraday).to receive(:post).and_return(mock_response)
      end

      it 'トークンを正常に取得できること' do
        result = service.exchange_code_for_token(
          code: code,
          redirect_uri: redirect_uri
        )

        expect(result[:id_token]).to eq(id_token)
        expect(result[:access_token]).to eq(access_token)
        expect(result[:expires_in]).to eq(3600)
        expect(result[:refresh_token]).to eq('mock-refresh-token')
      end
    end

    context 'LINE APIがエラーを返す場合' do
      let(:error_response) do
        instance_double(Faraday::Response, success?: false, status: 400, body: 'error')
      end

      before do
        allow(Faraday).to receive(:post).and_return(error_response)
      end

      it 'ExchangeErrorを発生させること' do
        expect {
          service.exchange_code_for_token(code: code, redirect_uri: redirect_uri)
        }.to raise_error(LineTokenExchangeService::ExchangeError, 'Failed to exchange authorization code')
      end
    end

    context 'ネットワークエラーが発生する場合' do
      before do
        allow(Faraday).to receive(:post).and_raise(Faraday::TimeoutError)
      end

      it 'ExchangeErrorを発生させること' do
        expect {
          service.exchange_code_for_token(
            code: code,
            redirect_uri: redirect_uri
          )
        }.to raise_error(LineTokenExchangeService::ExchangeError, 'Failed to connect to LINE')
      end
    end

    context '必須パラメータが不足している場合' do
      it 'codeが空の場合にArgumentErrorを発生させること' do
        expect {
          service.exchange_code_for_token(code: '', redirect_uri: redirect_uri)
        }.to raise_error(ArgumentError, 'Code and redirect_uri are required')
      end

      it 'redirect_uriが空の場合にArgumentErrorを発生させること' do
        expect {
          service.exchange_code_for_token(code: code, redirect_uri: '')
        }.to raise_error(ArgumentError, 'Code and redirect_uri are required')
      end
    end

    context '環境変数が設定されていない場合' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
      end

      it 'ArgumentErrorを発生させること' do
        expect {
          service.exchange_code_for_token(code: code, redirect_uri: redirect_uri)
        }.to raise_error(ArgumentError, 'LINE_LOGIN_CHANNEL_ID and LINE_LOGIN_CHANNEL_SECRET must be set')
      end
    end
  end
end
