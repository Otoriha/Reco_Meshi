require 'rails_helper'

RSpec.describe AllergyIngredient, type: :model do
  let(:user) { create(:user) }
  let(:ingredient) { create(:ingredient) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:ingredient) }
  end

  describe 'validations' do
    subject { build(:allergy_ingredient, user: user, ingredient: ingredient) }

    it { is_expected.to validate_presence_of(:severity) }

    it 'validates severity inclusion' do
      expect(subject).to allow_value('mild').for(:severity)
      expect(subject).to allow_value('moderate').for(:severity)
      expect(subject).to allow_value('severe').for(:severity)

      expect {
        build(:allergy_ingredient, user: user, ingredient: ingredient).tap do |ai|
          ai.severity = 'invalid'
        end
      }.to raise_error(ArgumentError, "'invalid' is not a valid severity")
    end

    it 'validates note length' do
      allergy_ingredient = build(:allergy_ingredient, note: 'a' * 500)
      expect(allergy_ingredient).to be_valid

      allergy_ingredient.note = 'a' * 501
      expect(allergy_ingredient).not_to be_valid
      expect(allergy_ingredient.errors[:note]).to include('は500文字以内で入力してください')
    end

    it 'allows blank note' do
      allergy_ingredient = build(:allergy_ingredient, note: nil)
      expect(allergy_ingredient).to be_valid

      allergy_ingredient.note = ''
      expect(allergy_ingredient).to be_valid
    end

    describe 'uniqueness validation' do
      before do
        create(:allergy_ingredient, user: user, ingredient: ingredient)
      end

      it 'does not allow duplicate user_id and ingredient_id combination' do
        duplicate = build(:allergy_ingredient, user: user, ingredient: ingredient)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:ingredient_id]).to include('は既に登録されています')
      end

      it 'allows same ingredient for different users' do
        another_user = create(:user, email: 'another@example.com')
        allergy_ingredient = build(:allergy_ingredient, user: another_user, ingredient: ingredient)
        expect(allergy_ingredient).to be_valid
      end

      it 'allows same user with different ingredients' do
        another_ingredient = create(:ingredient, name: 'そば')
        allergy_ingredient = build(:allergy_ingredient, user: user, ingredient: another_ingredient)
        expect(allergy_ingredient).to be_valid
      end
    end
  end

  describe 'enums' do
    it 'defines severity enum correctly' do
      allergy_ingredient = create(:allergy_ingredient, severity: :mild)
      expect(allergy_ingredient.severity).to eq('mild')
      expect(allergy_ingredient.severity_mild?).to be true
      expect(allergy_ingredient.severity_moderate?).to be false
      expect(allergy_ingredient.severity_severe?).to be false
    end

    it 'has correct severity values' do
      expect(AllergyIngredient.severities).to eq({ 'mild' => 0, 'moderate' => 1, 'severe' => 2 })
    end
  end

  describe 'scopes' do
    let!(:mild_allergy) { create(:allergy_ingredient, user: user, severity: :mild) }
    let!(:moderate_allergy) { create(:allergy_ingredient, user: user, severity: :moderate, ingredient: create(:ingredient, name: 'そば')) }
    let!(:severe_allergy) { create(:allergy_ingredient, user: user, severity: :severe, ingredient: create(:ingredient, name: '落花生')) }

    describe '.by_severity' do
      it 'filters by severity' do
        mild_results = AllergyIngredient.by_severity(:mild)
        expect(mild_results).to include(mild_allergy)
        expect(mild_results).not_to include(moderate_allergy, severe_allergy)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        results = AllergyIngredient.recent
        expect(results.first).to eq(severe_allergy)
        expect(results.last).to eq(mild_allergy)
      end
    end
  end

  describe '#severity_label' do
    it 'returns correct label for mild' do
      allergy_ingredient = build(:allergy_ingredient, severity: :mild)
      expect(allergy_ingredient.severity_label).to eq('軽度')
    end

    it 'returns correct label for moderate' do
      allergy_ingredient = build(:allergy_ingredient, severity: :moderate)
      expect(allergy_ingredient.severity_label).to eq('中程度')
    end

    it 'returns correct label for severe' do
      allergy_ingredient = build(:allergy_ingredient, severity: :severe)
      expect(allergy_ingredient.severity_label).to eq('重度')
    end
  end
end
