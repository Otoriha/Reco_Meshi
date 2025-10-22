require 'rails_helper'

RSpec.describe SendInventoryReminderJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:line_account) { create(:line_account, user: user, linked_at: Time.current) }
    let(:bot) { instance_double(LineBotService) }

    before do
      allow(LineBotService).to receive(:new).and_return(bot)
      allow(bot).to receive(:generate_liff_url).and_return("https://liff.line.me/test")
    end

    it 'LineBotServiceが正しく呼び出される' do
      allow(bot).to receive(:create_flex_message).and_return({})
      expect(bot).to receive(:push_message).with(line_account.line_user_id, anything)

      described_class.new.perform(user.id)
    end

    it 'メッセージにaltTextが含まれる' do
      line_account  # Ensure line_account is created

      expect(bot).to receive(:create_flex_message).with(
        "今日の在庫確認",
        anything
      ).and_return({})
      allow(bot).to receive(:push_message)

      described_class.new.perform(user.id)
    end

    it 'InventoryStatsServiceを使用する' do
      line_account  # Ensure line_account is created

      stats_service = instance_double(InventoryStatsService)
      allow(InventoryStatsService).to receive(:new).and_return(stats_service)
      allow(stats_service).to receive(:total_count).and_return(5)
      allow(stats_service).to receive(:expiring_soon_ingredients).and_return([])
      allow(bot).to receive(:create_flex_message).and_return({})
      allow(bot).to receive(:push_message)

      described_class.new.perform(user.id)

      expect(InventoryStatsService).to have_received(:new).with(user)
    end

    it 'LINE連携がない場合はスキップされる' do
      user_without_line = create(:user)

      expect(bot).not_to receive(:push_message)

      described_class.new.perform(user_without_line.id)
    end

    it 'linked_atがnilの場合はスキップされる' do
      create(:line_account, user: user, linked_at: nil)

      expect(bot).not_to receive(:push_message)

      described_class.new.perform(user.id)
    end

    it 'エラー時はログに記録してraiseする' do
      line_account  # Ensure line_account is created

      allow(bot).to receive(:create_flex_message).and_return({})
      allow(bot).to receive(:push_message).and_raise(StandardError.new("API Error"))

      expect(Rails.logger).to receive(:error).with(/Failed to send reminder/)
      expect {
        described_class.new.perform(user.id)
      }.to raise_error(StandardError)
    end

    it '在庫数がメッセージに含まれる' do
      line_account  # Ensure line_account is created

      create(:user_ingredient, user: user, status: 'available')
      create(:user_ingredient, user: user, status: 'available')

      expect(bot).to receive(:create_flex_message) do |alt_text, bubble|
        body_contents = bubble[:body][:contents]
        inventory_text = body_contents.find { |c| c[:text]&.match?(/現在の在庫/) }
        expect(inventory_text[:text]).to include("2品")
        {}
      end
      allow(bot).to receive(:push_message)

      described_class.new.perform(user.id)
    end

    it '期限切れ間近の食材がある場合、メッセージに含まれる' do
      line_account  # Ensure line_account is created

      ingredient = create(:ingredient, name: "トマト")
      create(:user_ingredient,
        user: user,
        ingredient: ingredient,
        expiry_date: 2.days.from_now.to_date,
        status: 'available'
      )

      expect(bot).to receive(:create_flex_message) do |alt_text, bubble|
        contents = bubble[:body][:contents]
        expect(contents.any? { |c| c[:text]&.include?("トマト") }).to be true
        {}
      end
      allow(bot).to receive(:push_message)

      described_class.new.perform(user.id)
    end
  end
end
