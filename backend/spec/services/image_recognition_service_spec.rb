require "rails_helper"

RSpec.describe ImageRecognitionService, type: :service do
  let(:user) { create(:user) }
  let(:test_image_path) { Rails.root.join("spec/fixtures/files/test_fridge.png") }
  let(:image_content) { File.read(test_image_path) }
  let(:uploaded_file) { fixture_file_upload(test_image_path, "image/png") }

  # Vision APIのモックレスポンス
  let(:mock_vision_result) do
    GoogleCloudVisionResult.new(
      [ { name: "tomato", score: 0.95 } ], # labels
      [ { name: "vegetable", score: 0.88 } ], # objects
      { full_text: "2024/12/31", blocks: [] }, # texts
      [ { name: "トマト", confidence: 0.95 }, { name: "玉ねぎ", confidence: 0.88 } ] # ingredients
    )
  end

  let(:mock_conversion_result) do
    {
      success: true,
      message: "Conversion completed successfully",
      metrics: {
        successful_conversions: 2,
        new_ingredients: 1,
        duplicate_updates: 1,
        total_recognized: 2,
        skipped_low_confidence: 0,
        unmatched_ingredients: 0,
        errors: []
      }
    }
  end

  describe "#recognize_and_convert" do
    context "文字列形式の画像コンテンツを使用する場合" do
      let(:service) { described_class.new(user: user, image_source: image_content) }

      before do
        # Vision APIサービスをモック化
        mock_vision_service = instance_double(GoogleCloudVisionService)
        allow(GoogleCloudVisionService).to receive(:new).and_return(mock_vision_service)
        allow(mock_vision_service).to receive(:analyze_image).and_return(mock_vision_result)

        # IngredientConverterServiceをモック化
        mock_converter = instance_double(IngredientConverterService)
        allow(IngredientConverterService).to receive(:new).and_return(mock_converter)
        allow(mock_converter).to receive(:convert_and_save).and_return(mock_conversion_result)

        # FridgeImageの作成をモック化
        mock_fridge_image = instance_double(FridgeImage, id: 123, user: user, created_at: Time.current)
        allow(FridgeImage).to receive(:create!).and_return(mock_fridge_image)
        allow(mock_fridge_image).to receive(:complete_with_result!)
        allow(mock_fridge_image).to receive(:update!)
        allow(mock_fridge_image).to receive(:fail_with_error!)
      end

      it "画像認識と在庫変換を正常に実行する" do
        result = service.recognize_and_convert

        expect(result).to be_a(Hash)
        expect(result[:success]).to be true
        expect(result[:recognized_ingredients]).to be_an(Array)
        expect(result[:recognized_ingredients].size).to eq 2
        expect(result[:conversion_metrics]).to be_a(Hash)
        expect(result[:message]).to eq "画像認識が完了しました"
      end

      it "GoogleCloudVisionServiceが正しく呼び出される" do
        expect_any_instance_of(GoogleCloudVisionService).to receive(:analyze_image)
          .with(image_content, features: %i[label object text])

        service.recognize_and_convert
      end

      it "IngredientConverterServiceが正しく呼び出される" do
        expect(IngredientConverterService).to receive(:new)
          .with(kind_of(FridgeImage))

        service.recognize_and_convert
      end
    end

    context "アップロードファイルを使用する場合" do
      let(:service) { described_class.new(user: user, image_source: uploaded_file) }

      before do
        # Vision APIサービスをモック化
        mock_vision_service = instance_double(GoogleCloudVisionService)
        allow(GoogleCloudVisionService).to receive(:new).and_return(mock_vision_service)
        allow(mock_vision_service).to receive(:analyze_image).and_return(mock_vision_result)

        # IngredientConverterServiceをモック化
        mock_converter = instance_double(IngredientConverterService)
        allow(IngredientConverterService).to receive(:new).and_return(mock_converter)
        allow(mock_converter).to receive(:convert_and_save).and_return(mock_conversion_result)

        # FridgeImageの作成をモック化
        mock_fridge_image = instance_double(FridgeImage, id: 123, user: user, created_at: Time.current)
        allow(FridgeImage).to receive(:create!).and_return(mock_fridge_image)
        allow(mock_fridge_image).to receive(:complete_with_result!)
        allow(mock_fridge_image).to receive(:update!)
        allow(mock_fridge_image).to receive(:fail_with_error!)
      end

      it "アップロードファイルから画像コンテンツを読み取り、認識を実行する" do
        result = service.recognize_and_convert

        expect(result[:success]).to be true
        expect(result[:recognized_ingredients]).to be_an(Array)
      end

      it "ファイルの内容がVision APIに渡される" do
        expect_any_instance_of(GoogleCloudVisionService).to receive(:analyze_image)
          .with(kind_of(String), features: %i[label object text])

        service.recognize_and_convert
      end
    end

    context "Vision APIでエラーが発生した場合" do
      let(:service) { described_class.new(user: user, image_source: image_content) }
      let(:error_vision_result) do
        GoogleCloudVisionResult.new(
          [], [], {},
          [ { name: "エラー", confidence: 0.0, error: "画像解析に失敗しました" } ]
        )
      end

      before do
        mock_vision_service = instance_double(GoogleCloudVisionService)
        allow(GoogleCloudVisionService).to receive(:new).and_return(mock_vision_service)
        allow(mock_vision_service).to receive(:analyze_image).and_return(error_vision_result)

        mock_fridge_image = instance_double(FridgeImage, id: 123, user: user)
        allow(FridgeImage).to receive(:create!).and_return(mock_fridge_image)
        allow(mock_fridge_image).to receive(:fail_with_error!)
      end

      it "エラーレスポンスを返す" do
        result = service.recognize_and_convert

        expect(result[:success]).to be false
        expect(result[:message]).to eq "画像解析に失敗しました"
        expect(result[:recognized_ingredients]).to eq []
      end
    end

    context "画像ファイルのサイズが制限を超える場合" do
      let(:large_content) { "x" * (25 * 1024 * 1024) } # 25MB
      let(:service) { described_class.new(user: user, image_source: large_content) }

      before do
        mock_fridge_image = instance_double(FridgeImage, id: 123, user: user)
        allow(FridgeImage).to receive(:create!).and_return(mock_fridge_image)
        allow(mock_fridge_image).to receive(:fail_with_error!)
      end

      it "画像サイズエラーを返す" do
        result = service.recognize_and_convert

        expect(result[:success]).to be false
        expect(result[:message]).to eq "画像の取得に失敗しました"
      end
    end

    context "画像コンテンツが空の場合" do
      let(:service) { described_class.new(user: user, image_source: "") }

      before do
        mock_fridge_image = instance_double(FridgeImage, id: 123, user: user)
        allow(FridgeImage).to receive(:create!).and_return(mock_fridge_image)
        allow(mock_fridge_image).to receive(:fail_with_error!)
      end

      it "画像取得エラーを返す" do
        result = service.recognize_and_convert

        expect(result[:success]).to be false
        expect(result[:message]).to eq "画像の取得に失敗しました"
      end
    end

    context "在庫変換でエラーが発生した場合" do
      let(:service) { described_class.new(user: user, image_source: image_content) }
      let(:error_conversion_result) do
        {
          success: false,
          message: "Conversion failed",
          metrics: {}
        }
      end

      before do
        # Vision APIサービスをモック化
        mock_vision_service = instance_double(GoogleCloudVisionService)
        allow(GoogleCloudVisionService).to receive(:new).and_return(mock_vision_service)
        allow(mock_vision_service).to receive(:analyze_image).and_return(mock_vision_result)

        # IngredientConverterServiceをモック化（エラーを返す）
        mock_converter = instance_double(IngredientConverterService)
        allow(IngredientConverterService).to receive(:new).and_return(mock_converter)
        allow(mock_converter).to receive(:convert_and_save).and_return(error_conversion_result)

        # FridgeImageの作成をモック化
        mock_fridge_image = instance_double(FridgeImage, id: 123, user: user, created_at: Time.current)
        allow(FridgeImage).to receive(:create!).and_return(mock_fridge_image)
        allow(mock_fridge_image).to receive(:complete_with_result!)
        allow(mock_fridge_image).to receive(:update!)
      end

      it "画像認識は成功するが、在庫変換でエラーがあっても結果を返す" do
        result = service.recognize_and_convert

        expect(result[:success]).to be true  # 画像認識自体は成功
        expect(result[:recognized_ingredients]).to be_an(Array)
        expect(result[:conversion_metrics][:success]).to be false  # 変換は失敗
      end
    end

    context "予期しない例外が発生した場合" do
      let(:service) { described_class.new(user: user, image_source: image_content) }

      before do
        allow(GoogleCloudVisionService).to receive(:new).and_raise(StandardError, "Unexpected error")

        mock_fridge_image = instance_double(FridgeImage, id: 123, user: user)
        allow(FridgeImage).to receive(:create!).and_return(mock_fridge_image)
        allow(mock_fridge_image).to receive(:fail_with_error!)
      end

      it "一般的なエラーメッセージを返す" do
        result = service.recognize_and_convert

        expect(result[:success]).to be false
        expect(result[:message]).to include "画像解析中にエラーが発生しました"
      end
    end
  end
end