require 'rails_helper'

RSpec.describe LineAccount, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    subject { build(:line_account) }

    it { should validate_presence_of(:line_user_id) }
    it { should validate_uniqueness_of(:line_user_id) }
    it { should validate_presence_of(:line_display_name) }
  end

  describe 'scopes' do
    let!(:linked_account) { create(:line_account, :linked) }
    let!(:unlinked_account) { create(:line_account, :unlinked) }

    describe '.linked' do
      it 'returns accounts with user_id present' do
        expect(LineAccount.linked).to include(linked_account)
        expect(LineAccount.linked).not_to include(unlinked_account)
      end
    end

    describe '.unlinked' do
      it 'returns accounts with user_id nil' do
        expect(LineAccount.unlinked).to include(unlinked_account)
        expect(LineAccount.unlinked).not_to include(linked_account)
      end
    end
  end

  describe '#linked?' do
    context 'when user_id and linked_at are present' do
      let(:line_account) { create(:line_account, :linked) }

      it 'returns true' do
        expect(line_account.linked?).to be true
      end
    end

    context 'when user_id is nil' do
      let(:line_account) { create(:line_account, user: nil, linked_at: nil) }

      it 'returns false' do
        expect(line_account.linked?).to be false
      end
    end

    context 'when linked_at is nil' do
      let(:user) { create(:user) }
      let(:line_account) { create(:line_account, user: user, linked_at: nil) }

      it 'returns false' do
        expect(line_account.linked?).to be false
      end
    end
  end

  describe '#link_to_user!' do
    let(:user) { create(:user) }
    let(:line_account) { create(:line_account, user: nil, linked_at: nil) }

    it 'links the account to the user and sets linked_at' do
      freeze_time = Time.current
      Timecop.freeze(freeze_time) do
        line_account.link_to_user!(user)

        expect(line_account.reload.user).to eq(user)
        expect(line_account.linked_at).to be_within(1.second).of(freeze_time)
      end
    end
  end

  describe '#unlink!' do
    let(:line_account) { create(:line_account, :linked) }

    it 'removes user association and linked_at' do
      line_account.unlink!

      expect(line_account.reload.user).to be_nil
      expect(line_account.linked_at).to be_nil
    end
  end
end
