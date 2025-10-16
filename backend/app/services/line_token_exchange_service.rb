class LineTokenExchangeService
  class ExchangeError < StandardError; end

  TOKEN_ENDPOINT = "https://api.line.me/oauth2/v2.1/token".freeze

  def self.exchange_code_for_token(code:, redirect_uri:)
    new.exchange_code_for_token(code: code, redirect_uri: redirect_uri)
  end

  def exchange_code_for_token(code:, redirect_uri:)
    # パラメータバリデーション
    if code.blank? || redirect_uri.blank?
      raise ArgumentError, "Code and redirect_uri are required"
    end

    # 環境変数バリデーション
    if ENV["LINE_LOGIN_CHANNEL_ID"].blank? || ENV["LINE_LOGIN_CHANNEL_SECRET"].blank?
      raise ArgumentError, "LINE_LOGIN_CHANNEL_ID and LINE_LOGIN_CHANNEL_SECRET must be set"
    end

    response = Faraday.post(TOKEN_ENDPOINT) do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form({
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri,
        client_id: ENV["LINE_LOGIN_CHANNEL_ID"],
        client_secret: ENV["LINE_LOGIN_CHANNEL_SECRET"]
      })
    end

    unless response.success?
      Rails.logger.error "LINE token exchange failed: #{response.status} - #{response.body}"
      raise ExchangeError, "Failed to exchange authorization code"
    end

    data = JSON.parse(response.body, symbolize_names: true)

    unless data[:id_token]
      raise ExchangeError, "ID token not found in response"
    end

    {
      id_token: data[:id_token],
      access_token: data[:access_token],
      expires_in: data[:expires_in],
      refresh_token: data[:refresh_token]
    }
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse LINE token response: #{e.message}"
    raise ExchangeError, "Invalid response from LINE"
  rescue Faraday::Error => e
    Rails.logger.error "LINE API request failed: #{e.message}"
    raise ExchangeError, "Failed to connect to LINE"
  end
end
