require "rails_helper"

RSpec.describe FavoriteRecipe, type: :model do
  subject(:favorite_recipe) { build(:favorite_recipe) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:recipe) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:recipe_id) }

    it "同一ユーザーが同じレシピを重複登録できない" do
      user = create(:user, :confirmed)
      recipe = create(:recipe, user: user)

      create(:favorite_recipe, user: user, recipe: recipe)
      duplicate = build(:favorite_recipe, user: user, recipe: recipe)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:recipe_id]).to include("レシピIDは既にお気に入りに追加されています")
    end
  end

  describe "scopes" do
    let!(:older) { create(:favorite_recipe, created_at: 2.days.ago) }
    let!(:newer) { create(:favorite_recipe, created_at: 1.day.ago) }

    it "recent は新しい順に並べる" do
      expect(described_class.recent).to eq([ newer, older ])
    end

    it "by_user は指定ユーザーのレコードのみ返す" do
      expect(described_class.by_user(older.user_id)).to include(older)
      expect(described_class.by_user(older.user_id)).not_to include(newer) if newer.user_id != older.user_id
    end

    it "by_recipe は指定レシピのレコードのみ返す" do
      expect(described_class.by_recipe(older.recipe_id)).to include(older)
      expect(described_class.by_recipe(older.recipe_id)).not_to include(newer) if newer.recipe_id != older.recipe_id
    end
  end
end
