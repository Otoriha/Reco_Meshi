require 'rails_helper'

RSpec.describe Devise::Mailer do
  before(:all) { skip('Confirmable is disabled') if ENV['CONFIRMABLE_ENABLED'] != 'true' }

  describe 'confirmation_instructions' do
    let(:user) { create(:user, confirmed_at: nil) }

    before do
      user.send_confirmation_instructions
    end

    def mail_body_text(mail)
      if mail.text_part
        mail.text_part.body.to_s
      elsif mail.body
        mail.body.to_s
      end
    end

    it 'renders the headers' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq('Confirmation instructions')
      expect(mail.to).to eq([ user.email ])
      expect(mail.from).to include('noreply@recomeshi.com')
    end

    it 'includes confirmation token in body' do
      mail = ActionMailer::Base.deliveries.last
      body_text = mail_body_text(mail)

      # Token is included in the URL, not as plain text
      expect(body_text).to include('confirmation_token=')
    end

    it 'includes frontend confirmation link' do
      mail = ActionMailer::Base.deliveries.last
      body_text = mail_body_text(mail)

      expect(body_text).to include('/settings/email-confirmation?confirmation_token=')
      # Should point to frontend, not backend API
      expect(body_text).not_to include('/api/v1/')
    end

    it 'includes MAILER_HOST in URL' do
      mail = ActionMailer::Base.deliveries.last
      body_text = mail_body_text(mail)

      expect(body_text).to include(Rails.application.config.action_mailer.default_url_options[:host])
    end
  end

  describe 'reset_password_instructions' do
    let(:user) { create(:user, confirmed_at: Time.current) }

    before do
      user.send_reset_password_instructions
    end

    def mail_body_text(mail)
      if mail.text_part
        mail.text_part.body.to_s
      elsif mail.body
        mail.body.to_s
      end
    end

    it 'renders the headers' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq('Reset password instructions')
      expect(mail.to).to eq([ user.email ])
      expect(mail.from).to include('noreply@recomeshi.com')
    end

    it 'includes reset password token in body' do
      mail = ActionMailer::Base.deliveries.last
      body_text = mail_body_text(mail)

      # Token is included in the URL, not as plain text
      expect(body_text).to include('reset_password_token=')
    end

    it 'includes frontend password reset link' do
      mail = ActionMailer::Base.deliveries.last
      body_text = mail_body_text(mail)

      expect(body_text).to include('/password/reset?reset_password_token=')
      # Should point to frontend, not backend API
      expect(body_text).not_to include('/api/v1/')
    end

    it 'includes MAILER_HOST in URL' do
      mail = ActionMailer::Base.deliveries.last
      body_text = mail_body_text(mail)

      expect(body_text).to include(Rails.application.config.action_mailer.default_url_options[:host])
    end
  end
end
