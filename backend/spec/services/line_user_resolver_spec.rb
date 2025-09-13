require 'rails_helper'

RSpec.describe LineUserResolver, type: :service do
  describe '.resolve_user_from_line_id' do
    let(:user) { create(:user) }
    let(:line_account) { create(:line_account, user: user, line_user_id: 'test_line_user_id') }

    context 'with valid line_user_id' do
      before { line_account }

      it 'returns the associated user' do
        result = described_class.resolve_user_from_line_id('test_line_user_id')
        expect(result).to eq(user)
      end
    end

    context 'with invalid line_user_id' do
      it 'returns nil for non-existent line_user_id' do
        result = described_class.resolve_user_from_line_id('non_existent_id')
        expect(result).to be_nil
      end

      it 'returns nil for blank line_user_id' do
        result = described_class.resolve_user_from_line_id('')
        expect(result).to be_nil
      end

      it 'returns nil for nil line_user_id' do
        result = described_class.resolve_user_from_line_id(nil)
        expect(result).to be_nil
      end
    end
  end
end