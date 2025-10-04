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

  describe "デフォルト値" do
    it "正しいデフォルト値を持つ" do
      setting = Setting.new
      expect(setting.default_servings).to eq(2)
      expect(setting.recipe_difficulty).to eq("medium")
      expect(setting.cooking_time).to eq(30)
      expect(setting.shopping_frequency).to eq("2-3日に1回")
    end
  end
end
