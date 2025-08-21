require 'rails_helper'

RSpec.describe GoogleCloudVisionService, type: :service do
  let(:mock_client) { double('Google Vision Client') }
  let(:service) { described_class.new(client: mock_client) }
  
  # テスト用画像データ（Base64エンコードされた小さなPNG）
  let(:test_image_bytes) { Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAI/hUQyTAAAAABJRU5ErkJggg==') }
  
  describe '#analyze_image' do
    context 'when image analysis is successful' do
      let(:mock_response) do
        double('BatchAnnotateImagesResponse').tap do |response|
          allow(response).to receive(:responses).and_return([mock_annotation])
        end
      end
      
      let(:mock_annotation) do
        double('AnnotateImageResponse').tap do |annotation|
          allow(annotation).to receive(:error).and_return(nil)
          allow(annotation).to receive(:label_annotations).and_return([mock_label])
          allow(annotation).to receive(:localized_object_annotations).and_return([mock_object])
          allow(annotation).to receive(:text_annotations).and_return([mock_text])
        end
      end
      
      let(:mock_label) do
        double('EntityAnnotation').tap do |label|
          allow(label).to receive(:description).and_return('Tomato')
          allow(label).to receive(:score).and_return(0.9)
          allow(label).to receive(:locale).and_return('en')
        end
      end
      
      let(:mock_object) do
        double('LocalizedObjectAnnotation').tap do |obj|
          allow(obj).to receive(:name).and_return('Vegetable')
          allow(obj).to receive(:score).and_return(0.8)
          allow(obj).to receive(:bounding_poly).and_return(mock_bounding_poly)
        end
      end
      
      let(:mock_bounding_poly) do
        double('BoundingPoly').tap do |poly|
          allow(poly).to receive(:normalized_vertices).and_return([
            double('NormalizedVertex', x: 0.1, y: 0.1),
            double('NormalizedVertex', x: 0.9, y: 0.9)
          ])
        end
      end
      
      let(:mock_text) do
        double('EntityAnnotation').tap do |text|
          allow(text).to receive(:description).and_return('2024/12/31')
          allow(text).to receive(:bounding_poly).and_return(mock_text_bounding_poly)
        end
      end
      
      let(:mock_text_bounding_poly) do
        double('BoundingPoly').tap do |poly|
          allow(poly).to receive(:vertices).and_return([
            double('Vertex', x: 10, y: 10),
            double('Vertex', x: 100, y: 50)
          ])
        end
      end
      
      before do
        allow(mock_client).to receive(:batch_annotate_images).and_return(mock_response)
      end
      
      it 'returns parsed vision result' do
        result = service.analyze_image(test_image_bytes)
        
        expect(result).to be_a(GoogleCloudVisionResult)
        expect(result.labels).to be_present
        expect(result.labels.first[:name]).to eq('tomato') # 実装でdowncaseされるため
        expect(result.labels.first[:score]).to eq(0.9)
        expect(result.objects).to be_present
        expect(result.texts[:full_text]).to eq('2024/12/31')
        expect(result.ingredients).to be_present
        expect(result.ingredients.first[:name]).to eq('トマト')
      end
      
      it 'filters labels by score threshold' do
        # 低いスコアのラベルを追加
        low_score_label = double('EntityAnnotation').tap do |label|
          allow(label).to receive(:description).and_return('Food')
          allow(label).to receive(:score).and_return(0.3)
          allow(label).to receive(:locale).and_return('en')
        end
        
        allow(mock_annotation).to receive(:label_annotations).and_return([mock_label, low_score_label])
        
        result = service.analyze_image(test_image_bytes)
        
        # 信頼度0.6以上のみ残る
        expect(result.labels.size).to eq(1)
        expect(result.labels.first[:name]).to eq('tomato')
      end
      
      it 'excludes common non-ingredient labels' do
        excluded_label = double('EntityAnnotation').tap do |label|
          allow(label).to receive(:description).and_return('Food')
          allow(label).to receive(:score).and_return(0.9)
          allow(label).to receive(:locale).and_return('en')
        end
        
        allow(mock_annotation).to receive(:label_annotations).and_return([mock_label, excluded_label])
        
        result = service.analyze_image(test_image_bytes)
        
        # 'Food'は除外される
        ingredient_names = result.ingredients.map { |i| i[:name] }
        expect(ingredient_names).not_to include('food')
        expect(ingredient_names).to include('トマト')
      end
    end
    
    context 'when image data is empty' do
      it 'returns error result' do
        result = service.analyze_image('')
        
        expect(result.ingredients.first[:error]).to eq('画像データが空です')
      end
    end
    
    context 'when Vision API returns error' do
      let(:mock_response) do
        double('BatchAnnotateImagesResponse').tap do |response|
          allow(response).to receive(:responses).and_return([mock_error_annotation])
        end
      end
      
      let(:mock_error_annotation) do
        double('AnnotateImageResponse').tap do |annotation|
          error = double('Status', message: 'Invalid image format')
          allow(annotation).to receive(:error).and_return(error)
        end
      end
      
      before do
        allow(mock_client).to receive(:batch_annotate_images).and_return(mock_response)
      end
      
      it 'returns error result' do
        result = service.analyze_image(test_image_bytes)
        
        expect(result.ingredients.first[:error]).to eq('画像解析に失敗しました: Invalid image format')
      end
    end
    
    context 'when Vision API raises retryable error' do
      before do
        allow(mock_client).to receive(:batch_annotate_images)
          .and_raise(Google::Cloud::DeadlineExceededError.new('Request timeout'))
      end
      
      it 'raises the error for Sidekiq retry' do
        expect {
          service.analyze_image(test_image_bytes)
        }.to raise_error(Google::Cloud::DeadlineExceededError)
      end
    end
    
    context 'when Vision API raises non-retryable error' do
      before do
        allow(mock_client).to receive(:batch_annotate_images)
          .and_raise(Google::Cloud::PermissionDeniedError.new('Access denied'))
      end
      
      it 'returns error result' do
        result = service.analyze_image(test_image_bytes)
        
        expect(result.ingredients.first[:error]).to eq('画像解析サービスでエラーが発生しました')
      end
    end
  end
  
  describe 'ingredient mapping through analyze_image' do
    let(:tomato_label) do
      double('Label').tap do |label|
        allow(label).to receive(:description).and_return('Tomato') # 大文字で返される
        allow(label).to receive(:score).and_return(0.9)
        allow(label).to receive(:locale).and_return('en')
      end
    end
    
    let(:chicken_label) do
      double('Label').tap do |label|
        allow(label).to receive(:description).and_return('Chicken')
        allow(label).to receive(:score).and_return(0.85)
        allow(label).to receive(:locale).and_return('en')
      end
    end
    
    let(:mock_response_with_ingredients) do
      double('Response').tap do |response|
        allow(response).to receive(:responses).and_return([mock_annotation_with_ingredients])
      end
    end
    
    let(:mock_annotation_with_ingredients) do
      double('Annotation').tap do |annotation|
        allow(annotation).to receive(:error).and_return(nil)
        allow(annotation).to receive(:label_annotations).and_return([tomato_label, chicken_label])
        allow(annotation).to receive(:localized_object_annotations).and_return([])
        allow(annotation).to receive(:text_annotations).and_return([])
      end
    end
    
    it 'maps various ingredient labels to Japanese names through public API' do
      allow(mock_client).to receive(:batch_annotate_images).and_return(mock_response_with_ingredients)
      
      result = service.analyze_image(test_image_bytes)
      
      ingredient_names = result.ingredients.map { |i| i[:name] }
      expect(ingredient_names).to include('トマト', '鶏肉')
    end
  end
end