class NonceStore
  class NonceError < StandardError; end
  class NonceNotFoundError < NonceError; end
  class NonceAlreadyUsedError < NonceError; end

  NONCE_TTL = 10.minutes.freeze
  NONCE_PREFIX = "line_nonce:".freeze

  def self.generate_and_store(session_id = nil)
    new.generate_and_store(session_id)
  end

  def self.verify_and_consume(nonce, session_id = nil)
    new.verify_and_consume(nonce, session_id)
  end

  def self.cleanup_expired
    new.cleanup_expired
  end

  def generate_and_store(session_id = nil)
    nonce = SecureRandom.uuid
    # session_idは後方互換性のため残すが使用しない（セッションレス化）
    key = cache_key(nonce)

    Rails.cache.write(key, Time.current.to_i, expires_in: NONCE_TTL)

    nonce
  end

  def verify_and_consume(nonce, session_id = nil)
    # session_idは後方互換性のため残すが使用しない（セッションレス化）
    key = cache_key(nonce)

    # Check if nonce exists
    stored_time = Rails.cache.read(key)

    raise NonceNotFoundError, "Nonce not found or expired" unless stored_time

    # Delete the nonce immediately to prevent replay
    Rails.cache.delete(key)

    # Verify the nonce is not too old (additional check)
    if Time.current.to_i - stored_time > NONCE_TTL.to_i
      raise NonceNotFoundError, "Nonce has expired"
    end

    true
  end

  def cleanup_expired
    # Redis automatically handles TTL expiration, so no manual cleanup needed
    # This method is provided for compatibility and potential future use
    true
  end

  private

  def cache_key(nonce)
    # セッションレス化: session_idを使わないシンプルなキー
    "#{NONCE_PREFIX}#{nonce}"
  end
end
