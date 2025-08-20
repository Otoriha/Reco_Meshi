require 'jwt'
require 'net/http'
require 'json'

class JwtVerifier
  class VerificationError < StandardError; end
  class InvalidTokenError < VerificationError; end
  class ExpiredTokenError < VerificationError; end
  class AudienceMismatchError < VerificationError; end
  class NonceMismatchError < VerificationError; end

  JWKS_URI = 'https://api.line.me/oauth2/v2.1/certs'.freeze
  JWKS_CACHE_KEY = 'line_jwks'.freeze
  JWKS_CACHE_TTL = 24.hours.freeze
  ISSUER = 'https://access.line.me'.freeze
  ALGORITHM = 'RS256'.freeze
  CLOCK_SKEW = 5.minutes.freeze

  def self.verify_id_token(id_token:, aud:, nonce: nil)
    new.verify_id_token(id_token: id_token, aud: aud, nonce: nonce)
  end

  def verify_id_token(id_token:, aud:, nonce: nil)
    header = decode_header(id_token)
    kid = header['kid']
    
    raise InvalidTokenError, 'Missing kid in token header' unless kid

    public_key = get_public_key(kid)
    payload = decode_and_verify_token(id_token, public_key, aud, nonce)
    
    {
      sub: payload['sub'],
      name: payload['name'],
      picture: payload['picture'],
      aud: payload['aud'],
      iss: payload['iss'],
      exp: payload['exp'],
      iat: payload['iat']
    }
  rescue JWT::ExpiredSignature
    raise ExpiredTokenError, 'Token has expired'
  rescue JWT::InvalidAudError
    raise AudienceMismatchError, 'Invalid audience'
  rescue JWT::InvalidIssuerError
    raise InvalidTokenError, 'Invalid issuer'
  rescue JWT::DecodeError => e
    raise InvalidTokenError, "Token decode error: #{e.message}"
  end

  private

  def decode_header(token)
    JWT.decode(token, nil, false).last
  rescue JWT::DecodeError => e
    raise InvalidTokenError, "Failed to decode token header: #{e.message}"
  end

  def get_public_key(kid)
    jwks = fetch_jwks
    key_data = jwks['keys'].find { |key| key['kid'] == kid }
    
    raise InvalidTokenError, "Public key not found for kid: #{kid}" unless key_data

    # Convert JWK to PEM format
    jwk = JWT::JWK.import(key_data)
    jwk.public_key
  rescue => e
    raise InvalidTokenError, "Failed to get public key: #{e.message}"
  end

  def fetch_jwks
    # Try to get from cache first
    cached_jwks = Rails.cache.read(JWKS_CACHE_KEY)
    return JSON.parse(cached_jwks) if cached_jwks

    # Fetch from LINE API
    uri = URI(JWKS_URI)
    response = Net::HTTP.get_response(uri)
    
    raise InvalidTokenError, "Failed to fetch JWKS: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    jwks_data = response.body
    
    # Cache the result
    Rails.cache.write(JWKS_CACHE_KEY, jwks_data, expires_in: JWKS_CACHE_TTL)
    
    JSON.parse(jwks_data)
  rescue => e
    raise InvalidTokenError, "Failed to fetch JWKS: #{e.message}"
  end

  def decode_and_verify_token(token, public_key, aud, nonce)
    options = {
      algorithm: ALGORITHM,
      iss: ISSUER,
      verify_iss: true,
      aud: aud,
      verify_aud: true,
      verify_exp: true,
      verify_iat: true,
      exp_leeway: CLOCK_SKEW.to_i,
      iat_leeway: CLOCK_SKEW.to_i
    }

    payload, _ = JWT.decode(token, public_key, true, options)
    
    # Verify nonce if provided
    if nonce && payload['nonce'] != nonce
      raise NonceMismatchError, 'Nonce mismatch'
    end

    payload
  end
end