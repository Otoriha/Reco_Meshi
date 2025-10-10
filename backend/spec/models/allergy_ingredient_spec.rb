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

  describe 'scopes' do
    let!(:allergy1) { create(:allergy_ingredient, user: user) }
    let!(:allergy2) { create(:allergy_ingredient, user: user, ingredient: create(:ingredient, name: 'そば')) }
    let!(:allergy3) { create(:allergy_ingredient, user: user, ingredient: create(:ingredient, name: '落花生')) }

    describe '.recent' do
      it 'orders by created_at desc' do
        results = AllergyIngredient.recent
        expect(results.first).to eq(allergy3)
        expect(results.last).to eq(allergy1)
      end
    end
  end
end
