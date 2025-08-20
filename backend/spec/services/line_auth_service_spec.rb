require 'rails_helper'

RSpec.describe LineAuthService do
  let(:id_token) { 'mock-id-token' }
  let(:nonce) { 'test-nonce-123' }
  let(:line_user_info) do
    {
      sub: 'U1234567890abcdef',
      name: 'Test User',
      picture: 'https://example.com/picture.jpg',
      aud: ENV['LINE_CHANNEL_ID'],
      iss: 'https://access.line.me'
    }
  end

  before do
    # Mock NonceStore
    allow(NonceStore).to receive(:verify_and_consume).and_return(true)
    
    # Mock JwtVerifier
    allow(JwtVerifier).to receive(:verify_id_token).and_return(line_user_info)
  end

  describe '.authenticate_with_id_token' do
    context 'with new LINE user' do
      it 'creates new LineAccount and User' do
        expect {
          result = described_class.authenticate_with_id_token(
            id_token: id_token,
            nonce: nonce
          )

          user = result[:user]
          line_account = result[:line_account]

          expect(user).to be_persisted
          expect(user.provider).to eq('line')
          expect(user.name).to eq('Test User')
          expect(user.email).to eq('line_U1234567890abcdef@line.local')

          expect(line_account).to be_persisted
          expect(line_account.line_user_id).to eq('U1234567890abcdef')
          expect(line_account.line_display_name).to eq('Test User')
          expect(line_account.line_picture_url).to eq('https://example.com/picture.jpg')
          expect(line_account.user).to eq(user)
          expect(line_account.linked_at).to be_present
        }.to change(User, :count).by(1)
         .and change(LineAccount, :count).by(1)
      end
    end

    context 'with existing unlinked LineAccount' do
      let!(:existing_line_account) do
        create(:line_account, 
               line_user_id: 'U1234567890abcdef',
               line_display_name: 'Old Name',
               user: nil,
               linked_at: nil)
      end

      it 'updates LineAccount and creates new User' do
        expect {
          result = described_class.authenticate_with_id_token(
            id_token: id_token,
            nonce: nonce
          )

          user = result[:user]
          line_account = result[:line_account]

          expect(line_account).to eq(existing_line_account)
          expect(line_account.reload.line_display_name).to eq('Test User')
          expect(line_account.user).to eq(user)
          expect(line_account.linked_at).to be_present

          expect(user).to be_persisted
          expect(user.provider).to eq('line')
        }.to change(User, :count).by(1)
         .and change(LineAccount, :count).by(0)
      end
    end

    context 'with existing linked LineAccount' do
      let!(:existing_user) { create(:user, provider: 'line') }
      let!(:existing_line_account) do
        create(:line_account, 
               line_user_id: 'U1234567890abcdef',
               user: existing_user,
               linked_at: 1.day.ago)
      end

      it 'returns existing User and updates LineAccount' do
        expect {
          result = described_class.authenticate_with_id_token(
            id_token: id_token,
            nonce: nonce
          )

          user = result[:user]
          line_account = result[:line_account]

          expect(user).to eq(existing_user)
          expect(line_account).to eq(existing_line_account)
          expect(line_account.reload.line_display_name).to eq('Test User')
        }.to change(User, :count).by(0)
         .and change(LineAccount, :count).by(0)
      end
    end

    context 'when nonce verification fails' do
      before do
        allow(NonceStore).to receive(:verify_and_consume)
          .and_raise(NonceStore::NonceNotFoundError, 'Nonce not found')
      end

      it 'raises AuthenticationError' do
        expect {
          described_class.authenticate_with_id_token(
            id_token: id_token,
            nonce: nonce
          )
        }.to raise_error(LineAuthService::AuthenticationError, 'Nonce not found')
      end
    end

    context 'when JWT verification fails' do
      before do
        allow(JwtVerifier).to receive(:verify_id_token)
          .and_raise(JwtVerifier::InvalidTokenError, 'Invalid token')
      end

      it 'raises AuthenticationError' do
        expect {
          described_class.authenticate_with_id_token(
            id_token: id_token,
            nonce: nonce
          )
        }.to raise_error(LineAuthService::AuthenticationError, 'Invalid token')
      end
    end
  end

  describe '.link_existing_user' do
    let(:user) { create(:user) }

    context 'with new LineAccount' do
      it 'creates LineAccount linked to user' do
        expect {
          result = described_class.link_existing_user(
            user: user,
            id_token: id_token,
            nonce: nonce
          )

          line_account = result[:line_account]

          expect(line_account).to be_persisted
          expect(line_account.user).to eq(user)
          expect(line_account.line_user_id).to eq('U1234567890abcdef')
          expect(line_account.linked_at).to be_present
        }.to change(LineAccount, :count).by(1)
      end
    end

    context 'with existing unlinked LineAccount' do
      let!(:existing_line_account) do
        create(:line_account, 
               line_user_id: 'U1234567890abcdef',
               user: nil,
               linked_at: nil)
      end

      it 'links existing LineAccount to user' do
        expect {
          result = described_class.link_existing_user(
            user: user,
            id_token: id_token,
            nonce: nonce
          )

          line_account = result[:line_account]

          expect(line_account).to eq(existing_line_account)
          expect(line_account.reload.user).to eq(user)
          expect(line_account.linked_at).to be_present
        }.to change(LineAccount, :count).by(0)
      end
    end

    context 'with LineAccount linked to another user' do
      let(:other_user) { create(:user) }
      let!(:existing_line_account) do
        create(:line_account, 
               line_user_id: 'U1234567890abcdef',
               user: other_user,
               linked_at: 1.day.ago)
      end

      it 'raises AuthenticationError' do
        expect {
          described_class.link_existing_user(
            user: user,
            id_token: id_token,
            nonce: nonce
          )
        }.to raise_error(LineAuthService::AuthenticationError, 'LINE account is already linked to another user')
      end
    end

    context 'with LineAccount already linked to same user' do
      let!(:existing_line_account) do
        create(:line_account, 
               line_user_id: 'U1234567890abcdef',
               user: user,
               linked_at: 1.day.ago)
      end

      it 'updates LineAccount information' do
        freeze_time do
          result = described_class.link_existing_user(
            user: user,
            id_token: id_token,
            nonce: nonce
          )

          line_account = result[:line_account]

          expect(line_account).to eq(existing_line_account)
          expect(line_account.reload.line_display_name).to eq('Test User')
          expect(line_account.linked_at).to eq(Time.current)
        end
      end
    end
  end
end