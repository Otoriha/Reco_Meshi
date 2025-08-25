class LineAuthService
  class AuthenticationError < StandardError; end

  def self.authenticate_with_id_token(id_token:, nonce:)
    new.authenticate_with_id_token(id_token: id_token, nonce: nonce)
  end

  def self.link_existing_user(user:, id_token:, nonce:)
    new.link_existing_user(user: user, id_token: id_token, nonce: nonce)
  end

  def authenticate_with_id_token(id_token:, nonce:)
    # Verify nonce (skip if nonce is empty for debugging)
    unless nonce.blank?
      NonceStore.verify_and_consume(nonce)
    end
    
    # Verify ID token
    Rails.logger.info "JWT検証開始 - aud: #{ENV['LINE_CHANNEL_ID']}, nonce: #{nonce}"
    line_user_info = JwtVerifier.verify_id_token(
      id_token: id_token,
      aud: ENV['LINE_CHANNEL_ID'], # IDトークンのaudはチャネルID
      nonce: nonce.present? ? nonce : nil # Skip nonce validation if empty
    )
    Rails.logger.info "JWT検証成功"

    # Find or create LineAccount
    line_account = find_or_create_line_account(line_user_info)
    
    # Find or create User
    user = find_or_create_user_for_line_account(line_account, line_user_info)
    
    { user: user, line_account: line_account }
  rescue JwtVerifier::VerificationError, NonceStore::NonceError => e
    raise AuthenticationError, e.message
  end

  def link_existing_user(user:, id_token:, nonce:)
    # Verify nonce (skip if nonce is empty for debugging)
    unless nonce.blank?
      NonceStore.verify_and_consume(nonce)
    end
    
    # Verify ID token
    line_user_info = JwtVerifier.verify_id_token(
      id_token: id_token,
      aud: ENV['LINE_CHANNEL_ID'], # IDトークンのaudはチャネルID
      nonce: nonce.present? ? nonce : nil # Skip nonce validation if empty
    )

    line_user_id = line_user_info[:sub]
    
    # Check if LINE account is already linked to another user
    existing_line_account = LineAccount.find_by(line_user_id: line_user_id)
    
    if existing_line_account&.user_id.present? && existing_line_account.user_id != user.id
      raise AuthenticationError, 'LINE account is already linked to another user'
    end

    # Create or update LineAccount and link to user
    line_account = if existing_line_account
                     existing_line_account.tap do |account|
                       account.update!(
                         user: user,
                         line_display_name: line_user_info[:name],
                         line_picture_url: line_user_info[:picture],
                         linked_at: Time.current
                       )
                     end
                   else
                     LineAccount.create!(
                       line_user_id: line_user_id,
                       user: user,
                       line_display_name: line_user_info[:name],
                       line_picture_url: line_user_info[:picture],
                       linked_at: Time.current
                     )
                   end

    { user: user, line_account: line_account }
  rescue JwtVerifier::VerificationError, NonceStore::NonceError => e
    raise AuthenticationError, e.message
  end

  private

  def find_or_create_line_account(line_user_info)
    line_user_id = line_user_info[:sub]
    
    line_account = LineAccount.find_by(line_user_id: line_user_id)
    
    if line_account
      # Update profile information
      line_account.update!(
        line_display_name: line_user_info[:name],
        line_picture_url: line_user_info[:picture]
      )
      line_account
    else
      # Create new LineAccount without user association
      LineAccount.create!(
        line_user_id: line_user_id,
        line_display_name: line_user_info[:name],
        line_picture_url: line_user_info[:picture]
      )
    end
  end

  def find_or_create_user_for_line_account(line_account, line_user_info)
    if line_account.user_id.present?
      # User already exists and is linked
      line_account.user
    else
      # Create new user for LINE authentication
      user = User.new(
        name: line_user_info[:name],
        email: generate_dummy_email(line_user_info[:sub]),
        password: SecureRandom.alphanumeric(16),
        provider: 'line'
      )
      
      # Skip email confirmation for LINE users
      if user.respond_to?(:skip_confirmation!)
        user.skip_confirmation!
      end
      
      user.save!
      
      # Link the LineAccount to the new User
      line_account.link_to_user!(user)
      
      user
    end
  end

  def generate_dummy_email(line_user_id)
    "line_#{line_user_id.downcase}@line.local"
  end
end