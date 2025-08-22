require 'rails_helper'

RSpec.describe ImageRecognitionJob, type: :job do
  let(:line_user_id) { 'test_user_123' }
  let(:message_id) { 'test_message_456' }
  let(:mock_line_service) { instance_double(LineBotService) }
  let(:mock_vision_service) { instance_double(GoogleCloudVisionService) }
  let(:test_image_data) { 'fake_image_data' }
  let(:line_account) { create(:line_account, :linked, line_user_id: line_user_id) }
  let(:user) { line_account.user }
  
  before do
    allow(LineBotService).to receive(:new).and_return(mock_line_service)
    allow(GoogleCloudVisionService).to receive(:new).and_return(mock_vision_service)
  end
  
  describe '#perform' do
    context 'when image recognition is successful' do
      let(:vision_result) do
        GoogleCloudVisionResult.new(
          labels: [{ name: 'tomato', score: 0.9 }],
          objects: [{ name: 'vegetable', score: 0.8 }],
          texts: { full_text: '2024/12/31', blocks: [] },
          ingredients: [
            { name: 'トマト', confidence: 0.85 },
            { name: '玉ねぎ', confidence: 0.75 }
          ]
        )
      end
      
      before do
        allow(mock_line_service).to receive(:get_message_content).and_return(test_image_data)
        allow(mock_vision_service).to receive(:analyze_image).and_return(vision_result)
        allow(mock_line_service).to receive(:push_message)
        allow(mock_line_service).to receive(:create_text_message).and_return({ type: 'text', text: 'test message' })
      end
      
      it 'fetches image, analyzes it, and sends results' do
        job = described_class.new
        job.perform(line_user_id, message_id)
        
        expect(mock_line_service).to have_received(:get_message_content).with(message_id)
        expect(mock_vision_service).to have_received(:analyze_image).with(test_image_data, features: %i[label object text])
        expect(mock_line_service).to have_received(:push_message).with(line_user_id, anything)
      end
      
      it 'sends recognition results with ingredients' do
        job = described_class.new
        
        expect(mock_line_service).to receive(:create_text_message) do |text|
          expect(text).to include('🥬 食材を認識しました！')
          expect(text).to include('トマト')
          expect(text).to include('玉ねぎ')
          expect(text).to include('85%')
          expect(text).to include('75%')
          { type: 'text', text: text }
        end
        
        job.perform(line_user_id, message_id)
      end
      
      it 'includes LIFF URL in the message' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('REACT_APP_LIFF_URL').and_return('https://liff.line.me/test-liff')
        
        job = described_class.new
        
        expect(mock_line_service).to receive(:create_text_message) do |text|
          expect(text).to include('https://liff.line.me/test-liff')
          { type: 'text', text: text }
        end
        
        job.perform(line_user_id, message_id)
      end
      
      it 'includes detected date information when available' do
        job = described_class.new
        message_mock = { type: 'text', text: '🥬 食材を認識しました！' }
        
        allow(mock_line_service).to receive(:create_text_message).and_return(message_mock)
        allow(mock_line_service).to receive(:push_message) do |user_id, message|
          expect(message[:text]).to include('💡 賞味期限らしき文字も見つかりました')
          expect(message[:text]).to include('2024/12/31')
        end
        
        job.perform(line_user_id, message_id)
      end
    end
    
    context 'when no ingredients are detected' do
      let(:empty_vision_result) do
        GoogleCloudVisionResult.new(
          labels: [],
          objects: [],
          texts: { full_text: '', blocks: [] },
          ingredients: []
        )
      end
      
      before do
        allow(mock_line_service).to receive(:get_message_content).and_return(test_image_data)
        allow(mock_vision_service).to receive(:analyze_image).and_return(empty_vision_result)
        allow(mock_line_service).to receive(:push_message)
        allow(mock_line_service).to receive(:create_text_message).and_return({ type: 'text', text: 'test message' })
      end
      
      it 'sends appropriate message for no detection' do
        job = described_class.new
        
        expect(mock_line_service).to receive(:create_text_message) do |text|
          expect(text).to include('🤔 申し訳ありません')
          expect(text).to include('食材を認識できませんでした')
          { type: 'text', text: text }
        end
        
        job.perform(line_user_id, message_id)
      end
    end
    
    context 'when image fetch fails' do
      before do
        allow(mock_line_service).to receive(:get_message_content).and_return(nil)
        allow(mock_line_service).to receive(:push_message)
        allow(mock_line_service).to receive(:create_text_message).and_return({ type: 'text', text: 'test message' })
      end
      
      it 'sends error message' do
        job = described_class.new
        
        expect(mock_line_service).to receive(:create_text_message) do |text|
          expect(text).to include('❌ 画像の取得に失敗しました')
          expect(text).to include('🔄 再度お試しいただくか、しばらく経ってからお試しください')
          { type: 'text', text: text }
        end
        
        job.perform(line_user_id, message_id)
      end
    end
    
    context 'when image is too large' do
      let(:large_image_data) { 'x' * 25.megabytes } # 25MB
      
      before do
        allow(mock_line_service).to receive(:get_message_content).and_return(large_image_data)
        allow(mock_line_service).to receive(:push_message)
        allow(mock_line_service).to receive(:create_text_message).and_return({ type: 'text', text: 'test message' })
      end
      
      it 'sends error message for oversized image' do
        job = described_class.new
        
        expect(mock_line_service).to receive(:create_text_message) do |text|
          expect(text).to include('❌ 画像の取得に失敗しました')
          expect(text).to include('🔄 再度お試しいただくか、しばらく経ってからお試しください')
          { type: 'text', text: text }
        end
        
        job.perform(line_user_id, message_id)
      end
    end
    
    context 'when vision analysis returns error' do
      let(:error_vision_result) do
        GoogleCloudVisionResult.new(
          labels: [],
          objects: [],
          texts: { full_text: '', blocks: [] },
          ingredients: [{ name: 'エラー', confidence: 0.0, error: 'Vision API エラー' }]
        )
      end
      
      before do
        allow(mock_line_service).to receive(:get_message_content).and_return(test_image_data)
        allow(mock_vision_service).to receive(:analyze_image).and_return(error_vision_result)
        allow(mock_line_service).to receive(:push_message)
        allow(mock_line_service).to receive(:create_text_message).and_return({ type: 'text', text: 'test message' })
      end
      
      it 'sends vision error message' do
        job = described_class.new
        
        expect(mock_line_service).to receive(:create_text_message) do |text|
          expect(text).to include('❌ Vision API エラー')
          { type: 'text', text: text }
        end
        
        job.perform(line_user_id, message_id)
      end
    end
    
    context 'when push message fails initially but succeeds on retry' do
      before do
        allow(mock_line_service).to receive(:get_message_content).and_return(test_image_data)
        allow(mock_vision_service).to receive(:analyze_image).and_return(
          GoogleCloudVisionResult.new(
            labels: [], objects: [], texts: { full_text: '', blocks: [] },
            ingredients: [{ name: 'トマト', confidence: 0.8 }]
          )
        )
        
        # 最初の呼び出しで失敗、リトライで成功
        call_count = 0
        allow(mock_line_service).to receive(:push_message) do
          call_count += 1
          raise 'Network error' if call_count == 1
          true # 2回目は成功
        end
        
        allow(mock_line_service).to receive(:create_text_message).and_return({ type: 'text', text: 'test' })
      end
      
      it 'retries push message on failure' do
        job = described_class.new
        
        expect(mock_line_service).to receive(:push_message).twice
        
        job.perform(line_user_id, message_id)
      end
    end
    
    context 'when an unexpected error occurs' do
      before do
        allow(mock_line_service).to receive(:get_message_content).and_return(test_image_data)
        allow(mock_vision_service).to receive(:analyze_image).and_raise(StandardError.new('Unexpected error'))
        allow(mock_line_service).to receive(:push_message)
      end
      
      it 'sends generic error message and re-raises error' do
        job = described_class.new
        
        expect(mock_line_service).to receive(:create_text_message) do |text|
          expect(text).to include('❌ 画像解析中にエラーが発生しました')
          { type: 'text', text: text }
        end
        
        expect { job.perform(line_user_id, message_id) }.to raise_error(StandardError)
      end
    end
  end
  
  describe 'date pattern extraction' do
    let(:job) { described_class.new }
    
    it 'extracts various date formats' do
      text = '賞味期限: 2024/12/31 消費期限: 24/01/15 製造日: 12/25'
      patterns = job.send(:extract_date_patterns, text)
      
      expect(patterns).to include('2024/12/31')
      expect(patterns).to include('24/01/15')
      expect(patterns.size).to eq(3) # 3つのパターンが抽出される
    end
    
    it 'extracts Japanese date format' do
      text = '賞味期限: 2024年12月31日'
      patterns = job.send(:extract_date_patterns, text)
      
      expect(patterns).to include('2024年12月31日')
    end
    
    it 'limits results to 3 patterns' do
      text = '2024/01/01 2024/02/02 2024/03/03 2024/04/04 2024/05/05'
      patterns = job.send(:extract_date_patterns, text)
      
      expect(patterns.size).to eq(3)
    end
  end

  describe 'FridgeImage integration' do
    let(:vision_result) do
      GoogleCloudVisionResult.new(
        labels: [{ name: 'tomato', score: 0.9 }],
        objects: [{ name: 'vegetable', score: 0.8 }],
        texts: { full_text: '2024/12/31', blocks: [] },
        ingredients: [
          { name: 'トマト', confidence: 0.85 },
          { name: '玉ねぎ', confidence: 0.75 }
        ]
      )
    end

    before do
      line_account # create line_account before test
      allow(mock_line_service).to receive(:get_message_content).and_return(test_image_data)
      allow(mock_vision_service).to receive(:analyze_image).and_return(vision_result)
      allow(mock_line_service).to receive(:push_message)
      allow(mock_line_service).to receive(:create_text_message).and_return({ type: 'text', text: 'test message' })
    end

    context 'when recognition is successful' do
      it 'creates FridgeImage record with processing status' do
        expect {
          described_class.new.perform(line_user_id, message_id)
        }.to change(FridgeImage, :count).by(1)

        fridge_image = FridgeImage.last
        expect(fridge_image.status).to eq('completed')
        expect(fridge_image.line_account).to eq(line_account)
        expect(fridge_image.user).to eq(user)
        expect(fridge_image.line_message_id).to eq(message_id)
        expect(fridge_image.captured_at).to be_present
        expect(fridge_image.recognized_at).to be_present
      end

      it 'saves recognition results to FridgeImage' do
        described_class.new.perform(line_user_id, message_id)

        fridge_image = FridgeImage.last
        expect(fridge_image.recognized_ingredients).to be_present
        expect(fridge_image.recognized_ingredients.size).to eq(2)
        expect(fridge_image.recognized_ingredients[0]['name']).to eq('トマト')
        expect(fridge_image.recognized_ingredients[0]['confidence']).to eq(0.85)
        expect(fridge_image.recognized_ingredients[1]['name']).to eq('玉ねぎ')
        expect(fridge_image.recognized_ingredients[1]['confidence']).to eq(0.75)
      end

      it 'saves metadata to FridgeImage' do
        described_class.new.perform(line_user_id, message_id)

        fridge_image = FridgeImage.last
        expect(fridge_image.image_metadata).to be_present
        expect(fridge_image.image_metadata['texts']).to eq(vision_result.texts.deep_stringify_keys)
        expect(fridge_image.image_metadata['api_version']).to eq('v1')
        expect(fridge_image.image_metadata['features_used']).to eq(%w[label object text])
        expect(fridge_image.image_metadata['processing_duration']).to be_a(Float)
      end
    end

    context 'when image fetch fails' do
      before do
        allow(mock_line_service).to receive(:get_message_content).and_return(nil)
      end

      it 'creates FridgeImage record with failed status' do
        expect {
          described_class.new.perform(line_user_id, message_id)
        }.to change(FridgeImage, :count).by(1)

        fridge_image = FridgeImage.last
        expect(fridge_image.status).to eq('failed')
        expect(fridge_image.error_message).to eq('画像の取得に失敗しました')
        expect(fridge_image.recognized_ingredients).to eq([])
      end
    end

    context 'when vision analysis has error' do
      let(:error_vision_result) do
        GoogleCloudVisionResult.new(
          labels: [],
          objects: [],
          texts: { full_text: '', blocks: [] },
          ingredients: [{ name: 'エラー', confidence: 0.0, error: 'Vision API エラー' }]
        )
      end

      before do
        allow(mock_vision_service).to receive(:analyze_image).and_return(error_vision_result)
      end

      it 'creates FridgeImage record with failed status and error message' do
        described_class.new.perform(line_user_id, message_id)

        fridge_image = FridgeImage.last
        expect(fridge_image.status).to eq('failed')
        expect(fridge_image.error_message).to eq('Vision API エラー')
      end
    end

    context 'when line_account does not exist' do
      let(:unknown_user_id) { 'unknown_user_999' }

      it 'creates FridgeImage without user association' do
        expect {
          described_class.new.perform(unknown_user_id, message_id)
        }.to change(FridgeImage, :count).by(1)

        fridge_image = FridgeImage.last
        expect(fridge_image.user).to be_nil
        expect(fridge_image.line_account).to be_nil
        expect(fridge_image.status).to eq('completed')
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(mock_vision_service).to receive(:analyze_image).and_raise(StandardError.new('Unexpected error'))
      end

      it 'updates FridgeImage status to failed with error message' do
        expect {
          described_class.new.perform(line_user_id, message_id)
        }.to change(FridgeImage, :count).by(1).and raise_error(StandardError)

        fridge_image = FridgeImage.last
        expect(fridge_image.status).to eq('failed')
        expect(fridge_image.error_message).to include('StandardError: Unexpected error')
      end
    end
  end
end