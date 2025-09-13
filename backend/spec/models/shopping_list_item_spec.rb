require 'rails_helper'

RSpec.describe ShoppingListItem, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:shopping_list) }
    it { is_expected.to belong_to(:ingredient) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0).is_less_than_or_equal_to(9999.99) }
    it { is_expected.to validate_presence_of(:unit) }

    describe 'unit inclusion validation' do
      let(:shopping_list_item) { build(:shopping_list_item) }

      it 'allows valid units' do
        ShoppingListItem::ALLOWED_UNITS.each do |unit|
          shopping_list_item.unit = unit
          expect(shopping_list_item).to be_valid
        end
      end

      it 'rejects invalid units' do
        shopping_list_item.unit = 'invalid_unit'
        expect(shopping_list_item).not_to be_valid
        expected_message = "は有効な単位を選択してください（#{ShoppingListItem::ALLOWED_UNITS.join('、')}）"
        expect(shopping_list_item.errors[:unit]).to include(expected_message)
      end
    end

    describe 'uniqueness validation' do
      let(:shopping_list) { create(:shopping_list) }
      let(:ingredient) { create(:ingredient) }

      before do
        create(:shopping_list_item, shopping_list: shopping_list, ingredient: ingredient)
      end

      it 'prevents duplicate ingredient in same shopping list' do
        duplicate_item = build(:shopping_list_item, shopping_list: shopping_list, ingredient: ingredient)
        expect(duplicate_item).not_to be_valid
        expect(duplicate_item.errors[:ingredient_id]).to include('は既にリストに追加されています')
      end

      it 'allows same ingredient in different shopping lists' do
        other_shopping_list = create(:shopping_list)
        item_in_other_list = build(:shopping_list_item, shopping_list: other_shopping_list, ingredient: ingredient)
        expect(item_in_other_list).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:shopping_list) { create(:shopping_list) }
    let!(:checked_item) { create(:shopping_list_item, :checked, shopping_list: shopping_list) }
    let!(:unchecked_item) { create(:shopping_list_item, :unchecked, shopping_list: shopping_list) }
    let!(:recent_item) { create(:shopping_list_item, shopping_list: shopping_list, created_at: 1.day.ago) }
    let!(:old_item) { create(:shopping_list_item, shopping_list: shopping_list, created_at: 1.week.ago) }

    describe '.checked' do
      it 'returns only checked items' do
        expect(ShoppingListItem.checked).to include(checked_item)
        expect(ShoppingListItem.checked).not_to include(unchecked_item)
      end
    end

    describe '.unchecked' do
      it 'returns only unchecked items' do
        expect(ShoppingListItem.unchecked).to include(unchecked_item)
        expect(ShoppingListItem.unchecked).not_to include(checked_item)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        expect(ShoppingListItem.recent.first.created_at).to be > ShoppingListItem.recent.last.created_at
      end
    end

    describe '.by_category' do
      let(:vegetable_ingredient) { create(:ingredient, category: 'vegetables') }
      let(:meat_ingredient) { create(:ingredient, category: 'meat') }
      let!(:vegetable_item) { create(:shopping_list_item, ingredient: vegetable_ingredient, shopping_list: shopping_list) }
      let!(:meat_item) { create(:shopping_list_item, ingredient: meat_ingredient, shopping_list: shopping_list) }

      it 'filters by ingredient category' do
        expect(ShoppingListItem.by_category('vegetables')).to include(vegetable_item)
        expect(ShoppingListItem.by_category('vegetables')).not_to include(meat_item)
      end

      it 'returns all when category is blank' do
        expect(ShoppingListItem.by_category('')).to include(vegetable_item, meat_item)
      end
    end

    describe '.ordered_by_ingredient_name' do
      let(:ingredient_a) { create(:ingredient, name: 'Apple') }
      let(:ingredient_z) { create(:ingredient, name: 'Zucchini') }
      let!(:item_z) { create(:shopping_list_item, ingredient: ingredient_z, shopping_list: shopping_list) }
      let!(:item_a) { create(:shopping_list_item, ingredient: ingredient_a, shopping_list: shopping_list) }

      it 'orders by ingredient name' do
        expect(ShoppingListItem.ordered_by_ingredient_name.first).to eq(item_a)
        expect(ShoppingListItem.ordered_by_ingredient_name.last).to eq(item_z)
      end
    end
  end

  describe 'callbacks' do
    let(:shopping_list_item) { create(:shopping_list_item, :unchecked) }

    describe 'before_update :set_checked_at' do
      it 'sets checked_at when item is checked' do
        expect { shopping_list_item.update!(is_checked: true) }
          .to change(shopping_list_item, :checked_at).from(nil)
      end

      it 'clears checked_at when item is unchecked' do
        shopping_list_item.update!(is_checked: true, checked_at: Time.current)
        expect { shopping_list_item.update!(is_checked: false) }
          .to change(shopping_list_item, :checked_at).to(nil)
      end

      it 'does not change checked_at when is_checked does not change' do
        shopping_list_item.update!(is_checked: true, checked_at: Time.current)
        original_checked_at = shopping_list_item.checked_at
        
        shopping_list_item.update!(quantity: 2.0)
        expect(shopping_list_item.checked_at).to eq(original_checked_at)
      end
    end
  end

  describe 'instance methods' do
    let(:shopping_list_item) { create(:shopping_list_item, :unchecked) }

    describe '#toggle_checked!' do
      it 'changes is_checked from false to true' do
        expect { shopping_list_item.toggle_checked! }
          .to change(shopping_list_item, :is_checked).from(false).to(true)
      end

      it 'changes is_checked from true to false' do
        shopping_list_item.update!(is_checked: true)
        expect { shopping_list_item.toggle_checked! }
          .to change(shopping_list_item, :is_checked).from(true).to(false)
      end
    end

    describe '#mark_as_checked!' do
      it 'sets is_checked to true when false' do
        expect { shopping_list_item.mark_as_checked! }
          .to change(shopping_list_item, :is_checked).from(false).to(true)
      end

      it 'does nothing when already checked' do
        shopping_list_item.update!(is_checked: true)
        expect { shopping_list_item.mark_as_checked! }
          .not_to change(shopping_list_item, :is_checked)
      end
    end

    describe '#mark_as_unchecked!' do
      it 'sets is_checked to false when true' do
        shopping_list_item.update!(is_checked: true)
        expect { shopping_list_item.mark_as_unchecked! }
          .to change(shopping_list_item, :is_checked).from(true).to(false)
      end

      it 'does nothing when already unchecked' do
        expect { shopping_list_item.mark_as_unchecked! }
          .not_to change(shopping_list_item, :is_checked)
      end
    end

    describe '#display_quantity_with_unit' do
      it 'displays whole numbers without decimals' do
        item = create(:shopping_list_item, quantity: 3.0, unit: '個')
        expect(item.display_quantity_with_unit).to eq('3個')
      end

      it 'displays decimals when present' do
        item = create(:shopping_list_item, quantity: 2.5, unit: 'g')
        expect(item.display_quantity_with_unit).to eq('2.5g')
      end
    end

    describe '#ingredient_name' do
      let(:ingredient) { create(:ingredient, name: 'トマト') }
      let(:item) { create(:shopping_list_item, ingredient: ingredient) }

      it 'returns ingredient name' do
        expect(item.ingredient_name).to eq('トマト')
      end
    end

    describe '#ingredient_category' do
      let(:ingredient) { create(:ingredient, category: 'vegetables') }
      let(:item) { create(:shopping_list_item, ingredient: ingredient) }

      it 'returns ingredient category' do
        expect(item.ingredient_category).to eq('vegetables')
      end
    end

    describe '#checked_recently?' do
      it 'returns true when checked within 1 day' do
        item = create(:shopping_list_item, :checked, checked_at: 12.hours.ago)
        expect(item.checked_recently?).to be true
      end

      it 'returns false when checked more than 1 day ago' do
        item = create(:shopping_list_item, :checked, checked_at: 2.days.ago)
        expect(item.checked_recently?).to be false
      end

      it 'returns false when never checked' do
        item = create(:shopping_list_item, :unchecked)
        expect(item.checked_recently?).to be false
      end
    end
  end
end
