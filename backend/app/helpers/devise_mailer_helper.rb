module DeviseMailerHelper
  def build_email_url(path, token_param, token)
    host = Rails.application.config.action_mailer.default_url_options[:host]
    protocol = Rails.application.config.action_mailer.default_url_options[:protocol]

    # Safely build URL avoiding double slashes
    host_without_trailing_slash = host.gsub(%r{/$}, "")
    "#{protocol}://#{host_without_trailing_slash}#{path}?#{token_param}=#{token}"
  end
end
