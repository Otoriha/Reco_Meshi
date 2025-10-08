require 'rails_helper'

RSpec.describe DislikedIngredient, type: :model do
  let(:user) { create(:user) }
  let(:ingredient) { create(:ingredient) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:ingredient) }
  end

  describe 'validations' do
    subject { build(:disliked_ingredient, user: user, ingredient: ingredient) }

    it { is_expected.to validate_presence_of(:priority) }

    it 'validates priority inclusion' do
      expect(subject).to allow_value('low').for(:priority)
      expect(subject).to allow_value('medium').for(:priority)
      expect(subject).to allow_value('high').for(:priority)

      expect {
        build(:disliked_ingredient, user: user, ingredient: ingredient).tap do |di|
          di.priority = 'invalid'
        end
      }.to raise_error(ArgumentError, "'invalid' is not a valid priority")
    end

    it 'validates reason length' do
      disliked_ingredient = build(:disliked_ingredient, reason: 'a' * 500)
      expect(disliked_ingredient).to be_valid

      disliked_ingredient.reason = 'a' * 501
      expect(disliked_ingredient).not_to be_valid
      expect(disliked_ingredient.errors[:reason]).to include('は500文字以内で入力してください')
    end

    it 'allows blank reason' do
      disliked_ingredient = build(:disliked_ingredient, reason: nil)
      expect(disliked_ingredient).to be_valid

      disliked_ingredient.reason = ''
      expect(disliked_ingredient).to be_valid
    end

    describe 'uniqueness validation' do
      before do
        create(:disliked_ingredient, user: user, ingredient: ingredient)
      end

      it 'does not allow duplicate user_id and ingredient_id combination' do
        duplicate = build(:disliked_ingredient, user: user, ingredient: ingredient)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:ingredient_id]).to include('は既に登録されています')
      end

      it 'allows same ingredient for different users' do
        another_user = create(:user, email: 'another@example.com')
        disliked_ingredient = build(:disliked_ingredient, user: another_user, ingredient: ingredient)
        expect(disliked_ingredient).to be_valid
      end

      it 'allows same user with different ingredients' do
        another_ingredient = create(:ingredient, name: 'セロリ')
        disliked_ingredient = build(:disliked_ingredient, user: user, ingredient: another_ingredient)
        expect(disliked_ingredient).to be_valid
      end
    end
  end

  describe 'enums' do
    it 'defines priority enum correctly' do
      disliked_ingredient = create(:disliked_ingredient, priority: :low)
      expect(disliked_ingredient.priority).to eq('low')
      expect(disliked_ingredient.priority_low?).to be true
      expect(disliked_ingredient.priority_medium?).to be false
      expect(disliked_ingredient.priority_high?).to be false
    end

    it 'has correct priority values' do
      expect(DislikedIngredient.priorities).to eq({ 'low' => 0, 'medium' => 1, 'high' => 2 })
    end
  end

  describe 'scopes' do
    let!(:low_disliked) { create(:disliked_ingredient, user: user, priority: :low) }
    let!(:medium_disliked) { create(:disliked_ingredient, user: user, priority: :medium, ingredient: create(:ingredient, name: 'セロリ')) }
    let!(:high_disliked) { create(:disliked_ingredient, user: user, priority: :high, ingredient: create(:ingredient, name: 'パクチー')) }

    describe '.by_priority' do
      it 'filters by priority' do
        low_results = DislikedIngredient.by_priority(:low)
        expect(low_results).to include(low_disliked)
        expect(low_results).not_to include(medium_disliked, high_disliked)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        results = DislikedIngredient.recent
        expect(results.first).to eq(high_disliked)
        expect(results.last).to eq(low_disliked)
      end
    end
  end

  describe '#priority_label' do
    it 'returns correct label for low' do
      disliked_ingredient = build(:disliked_ingredient, priority: :low)
      expect(disliked_ingredient.priority_label).to eq('低')
    end

    it 'returns correct label for medium' do
      disliked_ingredient = build(:disliked_ingredient, priority: :medium)
      expect(disliked_ingredient.priority_label).to eq('中')
    end

    it 'returns correct label for high' do
      disliked_ingredient = build(:disliked_ingredient, priority: :high)
      expect(disliked_ingredient.priority_label).to eq('高')
    end
  end
end
