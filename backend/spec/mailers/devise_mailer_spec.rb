require 'rails_helper'

RSpec.describe Devise::Mailer do
  describe 'confirmation_instructions' do
    let(:user) { create(:user, confirmed_at: nil) }

    before do
      user.send_confirmation_instructions
    end

    it 'renders the headers' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to include('confirmation')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to include('noreply@recomeshi.com')
    end

    it 'includes confirmation token in body' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.body.encoded).to include(user.confirmation_token)
    end

    it 'includes frontend confirmation link' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.body.encoded).to include('confirmation?confirmation_token=')
      # Should point to frontend, not backend API
      expect(mail.body.encoded).not_to include('/api/v1/')
    end

    it 'includes MAILER_HOST in URL' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.body.encoded).to include(Rails.application.config.action_mailer.default_url_options[:host])
    end
  end

  describe 'reset_password_instructions' do
    let(:user) { create(:user, confirmed_at: Time.current) }

    before do
      user.send_reset_password_instructions
    end

    it 'renders the headers' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to include('reset password')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to include('noreply@recomeshi.com')
    end

    it 'includes reset password token in body' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.body.encoded).to include(user.reset_password_token)
    end

    it 'includes frontend password reset link' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.body.encoded).to include('password/reset?reset_password_token=')
      # Should point to frontend, not backend API
      expect(mail.body.encoded).not_to include('/api/v1/')
    end

    it 'includes MAILER_HOST in URL' do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.body.encoded).to include(Rails.application.config.action_mailer.default_url_options[:host])
    end
  end
end
