require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:user_ingredients).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_ingredients) }
  end

  describe 'validations' do
    subject { create(:ingredient, name: 'TestIngredient') }

    it { is_expected.to validate_presence_of(:name) }
    it 'validates uniqueness of name' do
      create(:ingredient, name: 'UniqueTestIngredient')
      duplicate = build(:ingredient, name: 'UniqueTestIngredient')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:unit) }
    it { is_expected.to validate_length_of(:unit).is_at_most(20) }
    it { is_expected.to validate_length_of(:emoji).is_at_most(10) }
  end

  describe 'enums' do
    it 'defines category enum correctly' do
      expect(Ingredient.categories).to eq({
        'vegetables' => 'vegetables',
        'meat' => 'meat',
        'fish' => 'fish',
        'dairy' => 'dairy',
        'seasonings' => 'seasonings',
        'others' => 'others'
      })
    end

    it 'allows setting category through enum' do
      ingredient = build(:ingredient)

      expect { ingredient.vegetables! }.not_to raise_error
      expect(ingredient.vegetables?).to be true
      expect(ingredient.category).to eq('vegetables')
    end
  end

  describe 'scopes' do
    let!(:vegetable) { create(:ingredient, :vegetable) }
    let!(:meat) { create(:ingredient, :meat) }
    let!(:fish) { create(:ingredient, :fish) }

    describe '.by_category' do
      it 'returns ingredients in the specified category' do
        vegetables = Ingredient.by_category('vegetables')
        expect(vegetables).to include(vegetable)
        expect(vegetables).not_to include(meat, fish)
      end
    end

    describe '.search' do
      let!(:carrot) { create(:ingredient, name: 'テストにんじん') }
      let!(:potato) { create(:ingredient, name: 'テストじゃがいも') }

      it 'returns ingredients matching the query' do
        results = Ingredient.search('テストにんじん')
        expect(results).to include(carrot)
        expect(results).not_to include(potato)
      end

      it 'performs partial matching' do
        results = Ingredient.search('テスト')
        expect(results).to include(carrot, potato)
      end

      it 'returns all ingredients when query is blank' do
        results = Ingredient.search('')
        expect(results.count).to eq(Ingredient.count)
      end

      it 'returns all ingredients when query is nil' do
        results = Ingredient.search(nil)
        expect(results.count).to eq(Ingredient.count)
      end
    end
  end

  describe '.search_by_name' do
    let!(:carrot) { create(:ingredient, name: 'サーチテストにんじん') }
    let!(:potato) { create(:ingredient, name: 'サーチテストじゃがいも') }

    it 'returns ingredients matching the query' do
      results = Ingredient.search_by_name('サーチテストにんじん')
      expect(results).to include(carrot)
      expect(results).not_to include(potato)
    end

    it 'returns all ingredients when query is blank' do
      results = Ingredient.search_by_name('')
      expect(results.count).to eq(Ingredient.count)
    end

    it 'returns all ingredients when query is nil' do
      results = Ingredient.search_by_name(nil)
      expect(results.count).to eq(Ingredient.count)
    end
  end

  describe '#display_name_with_emoji' do
    context 'when emoji is present' do
      let(:ingredient) { build(:ingredient, name: 'にんじん', emoji: '🥕') }

      it 'returns name with emoji' do
        expect(ingredient.display_name_with_emoji).to eq('🥕 にんじん')
      end
    end

    context 'when emoji is not present' do
      let(:ingredient) { build(:ingredient, name: 'にんじん', emoji: nil) }

      it 'returns name only' do
        expect(ingredient.display_name_with_emoji).to eq('にんじん')
      end
    end

    context 'when emoji is blank' do
      let(:ingredient) { build(:ingredient, name: 'にんじん', emoji: '') }

      it 'returns name only' do
        expect(ingredient.display_name_with_emoji).to eq('にんじん')
      end
    end
  end
end
