require 'rails_helper'

RSpec.describe JwtVerifier do
  let(:channel_id) { '2007895268' }
  let(:nonce) { 'test-nonce-123' }
  
  # Mock JWK key for testing
  let(:test_private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:test_public_key) { test_private_key.public_key }
  let(:kid) { 'test-kid-123' }
  
  let(:jwks_response) do
    {
      'keys' => [
        {
          'kty' => 'RSA',
          'kid' => kid,
          'use' => 'sig',
          'alg' => 'RS256',
          'n' => Base64.urlsafe_encode64(test_public_key.n.to_s(2), padding: false),
          'e' => Base64.urlsafe_encode64(test_public_key.e.to_s(2), padding: false)
        }
      ]
    }
  end

  let(:valid_payload) do
    {
      'iss' => 'https://access.line.me',
      'aud' => channel_id,
      'sub' => 'U1234567890abcdef',
      'name' => 'Test User',
      'picture' => 'https://example.com/picture.jpg',
      'exp' => (Time.current + 1.hour).to_i,
      'iat' => Time.current.to_i,
      'nonce' => nonce
    }
  end

  let(:valid_token) do
    JWT.encode(valid_payload, test_private_key, 'RS256', { 'kid' => kid })
  end

  before do
    # Mock JWKS API response
    allow(Net::HTTP).to receive(:get_response).and_return(
      double('response', is_a?: true, body: jwks_response.to_json)
    )
    allow_any_instance_of(Net::HTTPResponse).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    
    # Clear cache before each test
    Rails.cache.clear
  end

  describe '.verify_id_token' do
    context 'with valid token' do
      it 'returns decoded payload' do
        result = described_class.verify_id_token(
          id_token: valid_token,
          aud: channel_id,
          nonce: nonce
        )

        expect(result[:sub]).to eq('U1234567890abcdef')
        expect(result[:name]).to eq('Test User')
        expect(result[:picture]).to eq('https://example.com/picture.jpg')
        expect(result[:aud]).to eq(channel_id)
        expect(result[:iss]).to eq('https://access.line.me')
      end
    end

    context 'with expired token' do
      let(:expired_payload) do
        valid_payload.merge(
          'exp' => (Time.current - 1.hour).to_i,
          'iat' => (Time.current - 2.hours).to_i
        )
      end
      let(:expired_token) { JWT.encode(expired_payload, test_private_key, 'RS256', { 'kid' => kid }) }

      it 'raises ExpiredTokenError' do
        expect {
          described_class.verify_id_token(
            id_token: expired_token,
            aud: channel_id,
            nonce: nonce
          )
        }.to raise_error(JwtVerifier::ExpiredTokenError, 'Token has expired')
      end
    end

    context 'with invalid audience' do
      let(:invalid_aud_payload) { valid_payload.merge('aud' => 'wrong-channel-id') }
      let(:invalid_aud_token) { JWT.encode(invalid_aud_payload, test_private_key, 'RS256', { 'kid' => kid }) }

      it 'raises AudienceMismatchError' do
        expect {
          described_class.verify_id_token(
            id_token: invalid_aud_token,
            aud: channel_id,
            nonce: nonce
          )
        }.to raise_error(JwtVerifier::AudienceMismatchError, 'Invalid audience')
      end
    end

    context 'with nonce mismatch' do
      it 'raises NonceMismatchError' do
        expect {
          described_class.verify_id_token(
            id_token: valid_token,
            aud: channel_id,
            nonce: 'wrong-nonce'
          )
        }.to raise_error(JwtVerifier::NonceMismatchError, 'Nonce mismatch')
      end
    end

    context 'with invalid issuer' do
      let(:invalid_iss_payload) { valid_payload.merge('iss' => 'https://invalid.issuer') }
      let(:invalid_iss_token) { JWT.encode(invalid_iss_payload, test_private_key, 'RS256', { 'kid' => kid }) }

      it 'raises InvalidTokenError' do
        expect {
          described_class.verify_id_token(
            id_token: invalid_iss_token,
            aud: channel_id,
            nonce: nonce
          )
        }.to raise_error(JwtVerifier::InvalidTokenError, 'Invalid issuer')
      end
    end

    context 'with missing kid in header' do
      let(:token_without_kid) { JWT.encode(valid_payload, test_private_key, 'RS256') }

      it 'raises InvalidTokenError' do
        expect {
          described_class.verify_id_token(
            id_token: token_without_kid,
            aud: channel_id,
            nonce: nonce
          )
        }.to raise_error(JwtVerifier::InvalidTokenError, 'Missing kid in token header')
      end
    end

    context 'with unknown kid' do
      let(:unknown_kid_token) { JWT.encode(valid_payload, test_private_key, 'RS256', { 'kid' => 'unknown-kid' }) }

      it 'raises InvalidTokenError' do
        expect {
          described_class.verify_id_token(
            id_token: unknown_kid_token,
            aud: channel_id,
            nonce: nonce
          )
        }.to raise_error(JwtVerifier::InvalidTokenError, /Public key not found for kid/)
      end
    end

    context 'when JWKS API fails' do
      before do
        allow(Net::HTTP).to receive(:get_response).and_return(
          double('response', is_a?: false, code: '500')
        )
        allow_any_instance_of(Net::HTTPResponse).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      end

      it 'raises InvalidTokenError' do
        expect {
          described_class.verify_id_token(
            id_token: valid_token,
            aud: channel_id,
            nonce: nonce
          )
        }.to raise_error(JwtVerifier::InvalidTokenError, /Failed to fetch JWKS/)
      end
    end
  end

  describe 'JWKS caching' do
    it 'caches JWKS response' do
      expect(Net::HTTP).to receive(:get_response).once.and_return(
        double('response', is_a?: true, body: jwks_response.to_json)
      )
      allow_any_instance_of(Net::HTTPResponse).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      # First call should fetch from API
      described_class.verify_id_token(
        id_token: valid_token,
        aud: channel_id,
        nonce: nonce
      )

      # Second call should use cache
      described_class.verify_id_token(
        id_token: valid_token,
        aud: channel_id,
        nonce: nonce
      )
    end
  end
end