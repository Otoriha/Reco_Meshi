require 'rails_helper'

RSpec.describe CheckInventoryRemindersJob, type: :job do
  describe '#perform' do
    context '10時に実行された場合' do
      let(:current_time) { Time.zone.parse("2025-01-15 10:00:00") }

      before do
        Timecop.freeze(current_time)
      end

      it '10:00に設定しているユーザーのジョブをエンキューする' do
        user = create(:user)
        create(:line_account, user: user, linked_at: Time.current)
        user.setting.update!(inventory_reminder_enabled: true, inventory_reminder_time: "10:00:00")

        expect(SendInventoryReminderJob).to receive(:perform_later).with(user.id)

        described_class.new.perform
      end

      it '22:00に設定しているユーザーは除外される' do
        user = create(:user)
        create(:line_account, user: user, linked_at: Time.current)
        user.setting.update!(inventory_reminder_enabled: true, inventory_reminder_time: "22:00:00")

        expect {
          described_class.new.perform
        }.not_to have_enqueued_job(SendInventoryReminderJob)
      end
    end

    context '22時に実行された場合' do
      let(:current_time) { Time.zone.parse("2025-01-15 22:00:00") }

      before do
        Timecop.freeze(current_time)
      end

      it '22:00に設定しているユーザーのジョブをエンキューする' do
        user = create(:user)
        create(:line_account, user: user, linked_at: Time.current)
        user.setting.update!(inventory_reminder_enabled: true, inventory_reminder_time: "22:00:00")

        expect(SendInventoryReminderJob).to receive(:perform_later).with(user.id)

        described_class.new.perform
      end
    end

    it 'LINE連携していないユーザーは除外される' do
      Timecop.freeze(Time.zone.parse("2025-01-15 10:00:00"))

      user = create(:user)
      create(:line_account, user: user, linked_at: nil)
      user.setting.update!(inventory_reminder_enabled: true, inventory_reminder_time: "10:00:00")

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(SendInventoryReminderJob)
    end

    it '通知無効のユーザーは除外される' do
      Timecop.freeze(Time.zone.parse("2025-01-15 10:00:00"))

      user = create(:user)
      create(:line_account, user: user, linked_at: Time.current)
      user.setting.update!(inventory_reminder_enabled: false, inventory_reminder_time: "10:00:00")

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(SendInventoryReminderJob)
    end
  end
end
