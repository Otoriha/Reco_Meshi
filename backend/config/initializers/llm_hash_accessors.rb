# Allow tests that stub method-style accessors on a Hash-based LLM config.
# This keeps runtime flexible (hash or object) and avoids partial-double errors.
class Hash
  def provider; self[:provider]; end
  def fallback_provider; self[:fallback_provider]; end
  def timeout_ms; self[:timeout_ms]; end
  def max_retries; self[:max_retries]; end
  def temperature; self[:temperature]; end
  def max_tokens; self[:max_tokens]; end
  def reasoning_effort; self[:reasoning_effort]; end
  def verbosity; self[:verbosity]; end
end

