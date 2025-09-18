require 'rails_helper'

RSpec.describe FridgeImage, type: :model do
  let(:user) { create(:user) }
  let(:line_account) { create(:line_account, user: user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:line_account).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'enums' do
    it 'defines status enum correctly' do
      expect(FridgeImage.statuses).to eq({
        'pending' => 'pending',
        'processing' => 'processing',
        'completed' => 'completed',
        'failed' => 'failed'
      })
    end
  end

  describe 'scopes' do
    let!(:old_image) { create(:fridge_image, user: user, line_account: line_account, created_at: 2.days.ago) }
    let!(:new_image) { create(:fridge_image, user: user, line_account: line_account, created_at: 1.day.ago) }
    let!(:completed_image) { create(:fridge_image, :completed, user: user, line_account: line_account) }
    let!(:failed_image) { create(:fridge_image, :failed, user: user, line_account: line_account) }

    describe '.recent' do
      it 'returns images ordered by created_at desc' do
        recent_ids = FridgeImage.recent.pluck(:id)
        expect(recent_ids.first).to eq([ completed_image.id, failed_image.id ].max)
        expect(recent_ids.last).to eq(old_image.id)
      end
    end

    describe '.with_ingredients' do
      it 'returns only completed images with ingredients' do
        result = FridgeImage.with_ingredients
        expect(result).to include(completed_image)
        expect(result).not_to include(failed_image, old_image, new_image)
      end
    end

    describe '.by_user' do
      let(:other_user) { create(:user) }
      let!(:other_user_image) { create(:fridge_image, user: other_user, line_account: nil) }

      it 'returns images for specific user' do
        user_images = FridgeImage.by_user(old_image.user)
        expect(user_images).to include(old_image, new_image)
        expect(user_images).not_to include(other_user_image)
      end
    end

    describe '.by_line_account' do
      let(:other_line_account) { create(:line_account) }
      let!(:other_line_image) { create(:fridge_image, line_account: other_line_account, user: nil) }

      it 'returns images for specific line_account' do
        line_images = FridgeImage.by_line_account(completed_image.line_account)
        expect(line_images).to include(completed_image, failed_image)
        expect(line_images).not_to include(other_line_image)
      end
    end
  end

  describe 'instance methods' do
    describe '#has_ingredients?' do
      context 'when status is completed and has ingredients' do
        let(:fridge_image) { create(:fridge_image, :completed) }

        it 'returns true' do
          expect(fridge_image.has_ingredients?).to be true
        end
      end

      context 'when status is not completed' do
        let(:fridge_image) { create(:fridge_image, :processing) }

        it 'returns false' do
          expect(fridge_image.has_ingredients?).to be false
        end
      end

      context 'when recognized_ingredients is empty' do
        let(:fridge_image) { create(:fridge_image, :without_ingredients) }

        it 'returns false' do
          expect(fridge_image.has_ingredients?).to be false
        end
      end
    end

    describe '#ingredient_count' do
      context 'when has ingredients' do
        let(:fridge_image) { create(:fridge_image, :completed) }

        it 'returns correct count' do
          expect(fridge_image.ingredient_count).to eq(2)
        end
      end

      context 'when has no ingredients' do
        let(:fridge_image) { create(:fridge_image, :processing) }

        it 'returns 0' do
          expect(fridge_image.ingredient_count).to eq(0)
        end
      end
    end

    describe '#top_ingredients' do
      let(:fridge_image) { create(:fridge_image, :completed) }

      it 'returns top ingredients up to limit' do
        top_ingredients = fridge_image.top_ingredients(1)
        expect(top_ingredients.size).to eq(1)
        expect(top_ingredients.first['name']).to eq('トマト')
      end
    end

    describe '#ingredient_names' do
      let(:fridge_image) { create(:fridge_image, :completed) }

      it 'returns array of ingredient names' do
        names = fridge_image.ingredient_names
        expect(names).to eq([ 'トマト', '玉ねぎ' ])
      end
    end

    describe '#start_processing!' do
      let(:fridge_image) { create(:fridge_image, :pending) }

      it 'updates status to processing and clears timestamps' do
        fridge_image.start_processing!
        expect(fridge_image.status).to eq('processing')
        expect(fridge_image.recognized_at).to be_nil
        expect(fridge_image.error_message).to be_nil
      end
    end

    describe '#complete_with_result!' do
      let(:fridge_image) { create(:fridge_image, :processing) }
      let(:ingredients_data) do
        [
          { 'name' => 'レタス', 'confidence' => 0.9 },
          { 'name' => 'きゅうり', 'confidence' => 0.8 }
        ]
      end
      let(:metadata) { { api_version: 'v1' }.deep_stringify_keys }

      it 'updates to completed status with results' do
        fridge_image.complete_with_result!(ingredients_data, metadata)

        expect(fridge_image.status).to eq('completed')
        expect(fridge_image.recognized_ingredients).to eq(ingredients_data)
        expect(fridge_image.image_metadata).to eq(metadata)
        expect(fridge_image.recognized_at).to be_present
        expect(fridge_image.error_message).to be_nil
      end
    end

    describe '#fail_with_error!' do
      let(:fridge_image) { create(:fridge_image, :processing) }
      let(:error_message) { 'API Error: Rate limit exceeded' }

      it 'updates to failed status with error message' do
        fridge_image.fail_with_error!(error_message)

        expect(fridge_image.status).to eq('failed')
        expect(fridge_image.error_message).to eq(error_message)
        expect(fridge_image.recognized_at).to be_present
      end
    end

    describe '#from_line?' do
      context 'when has line_message_id and line_account' do
        let(:fridge_image) { create(:fridge_image, :from_line) }

        it 'returns true' do
          expect(fridge_image.from_line?).to be true
        end
      end

      context 'when missing line_message_id' do
        let(:fridge_image) { create(:fridge_image, line_message_id: nil) }

        it 'returns false' do
          expect(fridge_image.from_line?).to be false
        end
      end
    end

    describe '#from_web?' do
      context 'when has user but no line_message_id' do
        let(:fridge_image) { create(:fridge_image, :from_web) }

        it 'returns true' do
          expect(fridge_image.from_web?).to be true
        end
      end

      context 'when has line_message_id' do
        let(:fridge_image) { create(:fridge_image, :from_line) }

        it 'returns false' do
          expect(fridge_image.from_web?).to be false
        end
      end
    end
  end
end
