require 'rails_helper'

RSpec.describe UserIngredient, type: :model do
  let(:user) { create(:user) }
  let(:ingredient) { create(:ingredient) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:ingredient) }
    it { is_expected.to belong_to(:fridge_image).optional }
  end

  describe 'validations' do
    subject { build(:user_ingredient, user: user, ingredient: ingredient) }

    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
    it 'validates status inclusion' do
      expect(subject).to allow_value('available').for(:status)
      expect(subject).to allow_value('used').for(:status)
      expect(subject).to allow_value('expired').for(:status)

      expect {
        build(:user_ingredient, user: user, ingredient: ingredient).tap do |ui|
          ui.status = 'invalid'
        end
      }.to raise_error(ArgumentError, "'invalid' is not a valid status")
    end

    describe 'expiry_date validation' do
      it 'allows future expiry dates' do
        user_ingredient = build(:user_ingredient, expiry_date: 1.week.from_now)
        expect(user_ingredient).to be_valid
      end

      it 'allows nil expiry date' do
        user_ingredient = build(:user_ingredient, expiry_date: nil)
        expect(user_ingredient).to be_valid
      end

      it 'does not allow past expiry dates' do
        user_ingredient = build(:user_ingredient, expiry_date: 1.day.ago)
        expect(user_ingredient).not_to be_valid
        expect(user_ingredient.errors[:expiry_date]).to include('過去の日付は設定できません')
      end
    end
  end

  describe 'enums' do
    it 'defines status enum correctly' do
      expect(UserIngredient.statuses).to eq({
        'available' => 'available',
        'used' => 'used',
        'expired' => 'expired'
      })
    end

    it 'allows setting status through enum' do
      user_ingredient = build(:user_ingredient)

      expect { user_ingredient.used! }.not_to raise_error
      expect(user_ingredient.used?).to be true
      expect(user_ingredient.status).to eq('used')
    end
  end

  describe 'scopes' do
    let!(:available_ingredient) do
      create(:user_ingredient, :available, expiry_date: 10.days.from_now, user: user, ingredient: ingredient)
    end
    let!(:used_ingredient) { create(:user_ingredient, :used, user: user, ingredient: ingredient) }
    let!(:expired_ingredient) { create(:user_ingredient, :expired, user: user, ingredient: ingredient) }
    let!(:expiring_soon_ingredient) { create(:user_ingredient, :expiring_soon, user: user, ingredient: ingredient) }

    describe '.available' do
      it 'returns only available ingredients' do
        results = UserIngredient.available
        expect(results).to include(available_ingredient, expiring_soon_ingredient)
        expect(results).not_to include(used_ingredient, expired_ingredient)
      end
    end

    describe '.expired' do
      it 'returns only expired ingredients' do
        results = UserIngredient.expired
        expect(results).to include(expired_ingredient)
        expect(results).not_to include(available_ingredient, used_ingredient, expiring_soon_ingredient)
      end
    end

    describe '.expiring_soon' do
      it 'returns ingredients expiring within 7 days by default' do
        # 明確に期限の遠い食材を作成
        far_future_ingredient = create(:user_ingredient, :available,
                                     expiry_date: 10.days.from_now, user: user, ingredient: ingredient)

        results = UserIngredient.expiring_soon
        expect(results).to include(expiring_soon_ingredient)
        expect(results).not_to include(far_future_ingredient, used_ingredient, expired_ingredient)
      end

      it 'excludes ingredients with nil expiry_date' do
        no_expiry_ingredient = create(:user_ingredient, :available,
                                    expiry_date: nil, user: user, ingredient: ingredient)

        results = UserIngredient.expiring_soon
        expect(results).not_to include(no_expiry_ingredient)
      end

      it 'accepts custom days parameter' do
        far_future = create(:user_ingredient, :available,
                           expiry_date: 10.days.from_now, user: user, ingredient: ingredient)

        results = UserIngredient.expiring_soon(15)
        expect(results).to include(expiring_soon_ingredient, far_future)
      end
    end

    describe '.by_category' do
      let(:vegetable) { create(:ingredient, :vegetable) }
      let(:meat) { create(:ingredient, :meat) }
      let!(:vegetable_ingredient) { create(:user_ingredient, user: user, ingredient: vegetable) }
      let!(:meat_ingredient) { create(:user_ingredient, user: user, ingredient: meat) }

      it 'returns ingredients of specified category' do
        results = UserIngredient.by_category('vegetables')
        expect(results).to include(vegetable_ingredient)
        expect(results).not_to include(meat_ingredient)
      end
    end

    describe '.recent' do
      it 'returns ingredients ordered by created_at desc' do
        old_ingredient = create(:user_ingredient, user: user, ingredient: ingredient)
        sleep 0.01  # 作成時間に差をつける
        new_ingredient = create(:user_ingredient, user: user, ingredient: ingredient)

        results = UserIngredient.recent.limit(2)
        expect(results.first.id).to eq(new_ingredient.id)
        expect(results.last.id).to eq(old_ingredient.id)
      end
    end
  end

  describe '#expired?' do
    context 'when expiry_date is nil' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: nil) }

      it 'returns false' do
        expect(user_ingredient.expired?).to be false
      end
    end

    context 'when expiry_date is in the past' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: 1.day.ago) }

      it 'returns true' do
        expect(user_ingredient.expired?).to be true
      end
    end

    context 'when expiry_date is in the future' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: 1.day.from_now) }

      it 'returns false' do
        expect(user_ingredient.expired?).to be false
      end
    end
  end

  describe '#expiring_soon?' do
    context 'when expiry_date is nil' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: nil) }

      it 'returns false' do
        expect(user_ingredient.expiring_soon?).to be false
      end
    end

    context 'when expiry_date is within default 7 days' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: 3.days.from_now) }

      it 'returns true' do
        expect(user_ingredient.expiring_soon?).to be true
      end
    end

    context 'when expiry_date is beyond default 7 days' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: 10.days.from_now) }

      it 'returns false' do
        expect(user_ingredient.expiring_soon?).to be false
      end
    end

    context 'with custom days parameter' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: 10.days.from_now) }

      it 'uses custom days' do
        expect(user_ingredient.expiring_soon?(15)).to be true
        expect(user_ingredient.expiring_soon?(5)).to be false
      end
    end
  end

  describe '#days_until_expiry' do
    context 'when expiry_date is nil' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: nil) }

      it 'returns nil' do
        expect(user_ingredient.days_until_expiry).to be_nil
      end
    end

    context 'when expiry_date is set' do
      let(:user_ingredient) { build(:user_ingredient, expiry_date: 5.days.from_now) }

      it 'returns days until expiry' do
        expect(user_ingredient.days_until_expiry).to eq(5)
      end
    end
  end

  describe '#display_name' do
    let(:ingredient) { create(:ingredient, name: 'ディスプレイテストにんじん', emoji: '🥕') }
    let(:user_ingredient) { build(:user_ingredient, ingredient: ingredient) }

    it 'returns ingredient display name with emoji' do
      expect(user_ingredient.display_name).to eq('🥕 ディスプレイテストにんじん')
    end
  end

  describe '#formatted_quantity' do
    let(:ingredient) { create(:ingredient, unit: 'g') }
    let(:user_ingredient) { build(:user_ingredient, ingredient: ingredient, quantity: 150.5) }

    it 'returns formatted quantity with unit' do
      expect(user_ingredient.formatted_quantity).to eq('150.5g')
    end
  end

  describe '.group_by_category' do
    let(:vegetable) { create(:ingredient, :vegetable) }
    let(:meat) { create(:ingredient, :meat) }
    let!(:vegetable_ingredient) { create(:user_ingredient, user: user, ingredient: vegetable) }
    let!(:meat_ingredient) { create(:user_ingredient, user: user, ingredient: meat) }

    it 'groups ingredients by category' do
      results = UserIngredient.group_by_category
      expect(results.keys).to include('Vegetables', 'Meat')
      expect(results['Vegetables']).to include(vegetable_ingredient)
      expect(results['Meat']).to include(meat_ingredient)
    end
  end
end
