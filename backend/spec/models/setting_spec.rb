require "rails_helper"

RSpec.describe Setting, type: :model do
  let(:user) { create(:user) }

  describe "アソシエーション" do
    it { is_expected.to belong_to(:user) }
  end

  describe "バリデーション" do
    subject { build(:setting, user: user) }

    it { is_expected.to validate_inclusion_of(:recipe_difficulty).in_array(%w[easy medium hard]) }
    it { is_expected.to validate_inclusion_of(:shopping_frequency).in_array([ "毎日", "2-3日に1回", "週に1回", "まとめ買い" ]) }
    it { is_expected.to validate_numericality_of(:default_servings).is_greater_than(0).is_less_than_or_equal_to(10) }
    it { is_expected.to validate_inclusion_of(:cooking_time).in_array([ 15, 30, 60, 999 ]) }
  end

  describe "通知設定のバリデーション" do
    describe "inventory_reminder_enabled" do
      it { is_expected.to allow_value(true).for(:inventory_reminder_enabled) }
      it { is_expected.to allow_value(false).for(:inventory_reminder_enabled) }
    end

    describe "inventory_reminder_time" do
      it { is_expected.to validate_presence_of(:inventory_reminder_time) }

      it "有効な時刻を受け入れる" do
        setting = build(:setting, inventory_reminder_time: Time.zone.parse('09:00'))
        expect(setting).to be_valid
      end
    end
  end

  describe "デフォルト値" do
    it "正しいデフォルト値を持つ" do
      setting = Setting.new
      expect(setting.default_servings).to eq(2)
      expect(setting.recipe_difficulty).to eq("medium")
      expect(setting.cooking_time).to eq(30)
      expect(setting.shopping_frequency).to eq("2-3日に1回")
      expect(setting.inventory_reminder_enabled).to eq(false)
      expect(setting.inventory_reminder_time.strftime('%H:%M')).to eq('09:00')
    end
  end
end
