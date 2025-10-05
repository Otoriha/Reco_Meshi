require "rails_helper"

RSpec.describe User, type: :model do
  describe "アソシエーション" do
    it { is_expected.to have_one(:line_account).dependent(:destroy) }
    it { is_expected.to have_one(:setting).dependent(:destroy) }
    it { is_expected.to have_many(:fridge_images).dependent(:destroy) }
    it { is_expected.to have_many(:user_ingredients).dependent(:destroy) }
    it { is_expected.to have_many(:recipes).dependent(:destroy) }
    it { is_expected.to have_many(:recipe_histories).dependent(:destroy) }
    it { is_expected.to have_many(:shopping_lists).dependent(:destroy) }
    it { is_expected.to have_many(:favorite_recipes).dependent(:destroy) }
  end

  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(50) }
    it { is_expected.to validate_inclusion_of(:provider).in_array(%w[email line]) }
  end

  describe "コールバック" do
    describe "after_create :build_default_setting" do
      it "ユーザー作成時にデフォルトのsettingが作成される" do
        user = create(:user)
        expect(user.setting).to be_present
        expect(user.setting.default_servings).to eq(2)
        expect(user.setting.recipe_difficulty).to eq("medium")
        expect(user.setting.cooking_time).to eq(30)
        expect(user.setting.shopping_frequency).to eq("2-3日に1回")
      end
    end
  end
end
