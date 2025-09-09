require 'rails_helper'

RSpec.describe RecipeHistory, type: :model do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:recipe) }
  end

  describe 'validations' do
    subject { build(:recipe_history) }

    it { should validate_presence_of(:cooked_at) }

    describe 'rating validation' do
      it 'allows nil rating' do
        recipe_history = build(:recipe_history, rating: nil)
        expect(recipe_history).to be_valid
      end

      it 'allows valid ratings (1-5)' do
        (1..5).each do |rating|
          recipe_history = build(:recipe_history, rating: rating)
          expect(recipe_history).to be_valid
        end
      end

      it 'rejects ratings below 1' do
        recipe_history = build(:recipe_history, rating: 0)
        expect(recipe_history).not_to be_valid
        expect(recipe_history.errors[:rating]).to be_present
      end

      it 'rejects ratings above 5' do
        recipe_history = build(:recipe_history, rating: 6)
        expect(recipe_history).not_to be_valid
        expect(recipe_history.errors[:rating]).to be_present
      end

      it 'rejects non-integer ratings' do
        recipe_history = build(:recipe_history, rating: 3.5)
        expect(recipe_history).not_to be_valid
        expect(recipe_history.errors[:rating]).to be_present
      end

      it 'rejects string ratings' do
        recipe_history = build(:recipe_history, rating: 'good')
        expect(recipe_history).not_to be_valid
        expect(recipe_history.errors[:rating]).to be_present
      end
    end
  end

  describe 'scopes' do
    let!(:recent_history) { create(:recipe_history, cooked_at: 1.day.ago) }
    let!(:old_history) { create(:recipe_history, cooked_at: 1.week.ago) }
    let!(:rated_history) { create(:recipe_history, :rated) }
    let!(:unrated_history) { create(:recipe_history, rating: nil) }

    describe '.recent' do
      it 'orders by cooked_at desc' do
        histories = [recent_history, old_history]
        recent_ordered = RecipeHistory.where(id: histories.map(&:id)).recent
        expect(recent_ordered.first).to eq(recent_history)
      end
    end

    describe '.rated' do
      it 'returns only rated histories' do
        expect(RecipeHistory.rated).to include(rated_history)
        expect(RecipeHistory.rated).not_to include(unrated_history)
      end
    end

    describe '.unrated' do
      it 'returns only unrated histories' do
        expect(RecipeHistory.unrated).to include(unrated_history)
        expect(RecipeHistory.unrated).not_to include(rated_history)
      end
    end

    describe '.by_user' do
      it 'filters by user_id' do
        expect(RecipeHistory.by_user(recent_history.user_id)).to include(recent_history)
      end
    end

    describe '.by_recipe' do
      it 'filters by recipe_id' do
        expect(RecipeHistory.by_recipe(recent_history.recipe_id)).to include(recent_history)
      end
    end
  end

  describe 'constants' do
    it 'defines RATING_RANGE' do
      expect(RecipeHistory::RATING_RANGE).to eq(1..5)
    end
  end

  describe 'instance methods' do
    let(:recipe_history) { create(:recipe_history, cooked_at: Time.zone.parse('2025-01-15 14:30:00')) }

    describe '#cooked_date' do
      it 'returns formatted date in Japanese' do
        expect(recipe_history.cooked_date).to eq('2025年01月15日')
      end
    end

    describe '#cooked_time' do
      it 'returns formatted time' do
        expect(recipe_history.cooked_time).to eq('14:30')
      end
    end
  end
end
