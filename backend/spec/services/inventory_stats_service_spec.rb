require 'rails_helper'

RSpec.describe InventoryStatsService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#total_count' do
    it 'availableステータスの在庫のみをカウントする' do
      create(:user_ingredient, user: user, status: 'available')
      create(:user_ingredient, user: user, status: 'used')
      create(:user_ingredient, user: user, status: 'expired')

      expect(service.total_count).to eq(1)
    end

    it '在庫がない場合は0を返す' do
      expect(service.total_count).to eq(0)
    end
  end

  describe '#expiring_soon_ingredients' do
    it '3日以内に期限切れの食材を取得する' do
      expiring = create(:user_ingredient,
        user: user,
        expiry_date: 2.days.from_now.to_date,
        status: 'available'
      )
      create(:user_ingredient,
        user: user,
        expiry_date: 10.days.from_now.to_date,
        status: 'available'
      )

      expect(service.expiring_soon_ingredients).to include(expiring)
      expect(service.expiring_soon_ingredients.size).to eq(1)
    end

    it 'usedステータスの食材は除外される' do
      create(:user_ingredient,
        user: user,
        expiry_date: 2.days.from_now.to_date,
        status: 'used'
      )

      expect(service.expiring_soon_ingredients).to be_empty
    end

    it '最大3件までに制限される' do
      4.times do
        create(:user_ingredient,
          user: user,
          expiry_date: 2.days.from_now.to_date,
          status: 'available'
        )
      end

      expect(service.expiring_soon_ingredients.size).to eq(3)
    end
  end

  describe '#has_ingredients?' do
    it '在庫がある場合trueを返す' do
      create(:user_ingredient, user: user, status: 'available')
      expect(service.has_ingredients?).to be true
    end

    it '在庫がない場合falseを返す' do
      expect(service.has_ingredients?).to be false
    end

    it 'usedステータスのみの場合falseを返す' do
      create(:user_ingredient, user: user, status: 'used')
      expect(service.has_ingredients?).to be false
    end
  end
end
