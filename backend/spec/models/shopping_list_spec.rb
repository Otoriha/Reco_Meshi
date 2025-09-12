require 'rails_helper'

RSpec.describe ShoppingList, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:recipe).optional }
    it { is_expected.to have_many(:shopping_list_items).dependent(:destroy) }
    it { is_expected.to have_many(:ingredients).through(:shopping_list_items) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    it { is_expected.to validate_length_of(:note).is_at_most(1000) }
  end

  describe 'enums' do
    it 'defines status enum correctly' do
      expect(ShoppingList.statuses).to eq({
        'pending' => 0,
        'in_progress' => 1,
        'completed' => 2
      })
    end

    it 'allows valid status values' do
      shopping_list = build(:shopping_list)
      
      expect { shopping_list.status = :pending }.not_to raise_error
      expect { shopping_list.status = :in_progress }.not_to raise_error
      expect { shopping_list.status = :completed }.not_to raise_error
    end
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:recent_list) { create(:shopping_list, user: user, created_at: 1.day.ago) }
    let!(:old_list) { create(:shopping_list, user: user, created_at: 1.week.ago) }
    let!(:pending_list) { create(:shopping_list, user: user, status: :pending) }
    let!(:completed_list) { create(:shopping_list, user: user, status: :completed) }

    describe '.recent' do
      it 'orders by created_at desc' do
        # 特定のユーザーのリストだけをテスト
        user_lists = [recent_list, old_list, pending_list, completed_list]
        results = ShoppingList.where(id: user_lists.map(&:id)).recent
        
        # 時系列順（降順）でソートされているかを確認
        timestamps = results.map(&:created_at)
        expect(timestamps).to eq(timestamps.sort.reverse)
      end
    end

    describe '.by_status' do
      it 'filters by status when provided' do
        expect(ShoppingList.by_status(:pending)).to include(pending_list)
        expect(ShoppingList.by_status(:pending)).not_to include(completed_list)
      end

      it 'returns all when status is blank' do
        expect(ShoppingList.by_status('')).to include(pending_list, completed_list)
      end
    end

    describe '.by_user' do
      let(:other_user) { create(:user) }
      let!(:other_list) { create(:shopping_list, user: other_user) }

      it 'filters by user_id' do
        expect(ShoppingList.by_user(user.id)).to include(recent_list)
        expect(ShoppingList.by_user(user.id)).not_to include(other_list)
      end
    end

    describe '.active' do
      let!(:in_progress_list) { create(:shopping_list, user: user, status: :in_progress) }

      it 'includes pending and in_progress' do
        expect(ShoppingList.active).to include(pending_list, in_progress_list)
        expect(ShoppingList.active).not_to include(completed_list)
      end
    end

    describe '.completed' do
      it 'includes only completed lists' do
        expect(ShoppingList.completed).to include(completed_list)
        expect(ShoppingList.completed).not_to include(pending_list)
      end
    end
  end

  describe 'instance methods' do
    let(:shopping_list) { create(:shopping_list, :with_items) }

    describe '#mark_as_completed!' do
      it 'updates status to completed' do
        expect { shopping_list.mark_as_completed! }
          .to change(shopping_list, :status).to('completed')
      end
    end

    describe '#mark_as_in_progress!' do
      it 'updates status to in_progress' do
        expect { shopping_list.mark_as_in_progress! }
          .to change(shopping_list, :status).to('in_progress')
      end
    end

    describe '#unchecked_items_count' do
      let(:shopping_list) { create(:shopping_list, :with_checked_items) }

      it 'returns count of unchecked items' do
        expect(shopping_list.unchecked_items_count).to eq(1)
      end
    end

    describe '#total_items_count' do
      it 'returns total count of items' do
        expect(shopping_list.total_items_count).to eq(3)
      end
    end

    describe '#completion_percentage' do
      context 'with no items' do
        let(:empty_list) { create(:shopping_list) }

        it 'returns 0' do
          expect(empty_list.completion_percentage).to eq(0)
        end
      end

      context 'with checked items' do
        let(:shopping_list) { create(:shopping_list, :with_checked_items) }

        it 'returns correct percentage' do
          expect(shopping_list.completion_percentage).to eq(66.7)
        end
      end
    end

    describe '#display_title' do
      context 'with custom title' do
        let(:shopping_list) { create(:shopping_list, title: 'カスタムタイトル') }

        it 'returns custom title' do
          expect(shopping_list.display_title).to eq('カスタムタイトル')
        end
      end

      context 'without title but with recipe' do
        let(:recipe) { create(:recipe, title: 'カレー') }
        let(:shopping_list) { create(:shopping_list, :with_recipe, recipe: recipe, title: nil) }

        it 'returns recipe-based title' do
          expect(shopping_list.display_title).to eq('カレーの買い物リスト')
        end
      end

      context 'without title and recipe' do
        let(:shopping_list) { create(:shopping_list, title: nil, recipe: nil) }

        it 'returns default title' do
          expect(shopping_list.display_title).to eq('買い物リスト')
        end
      end
    end

    describe '#can_be_completed?' do
      context 'with unchecked items' do
        let(:shopping_list) { create(:shopping_list, :with_checked_items) }

        it 'returns false' do
          expect(shopping_list.can_be_completed?).to be false
        end
      end

      context 'with all items checked' do
        let(:shopping_list) { create(:shopping_list, :with_items) }

        before do
          shopping_list.shopping_list_items.update_all(is_checked: true)
        end

        it 'returns true' do
          expect(shopping_list.can_be_completed?).to be true
        end
      end

      context 'with no items' do
        let(:shopping_list) { create(:shopping_list) }

        it 'returns false' do
          expect(shopping_list.can_be_completed?).to be false
        end
      end
    end
  end
end