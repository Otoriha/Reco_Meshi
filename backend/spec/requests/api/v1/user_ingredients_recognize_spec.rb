require "rails_helper"

RSpec.describe "Api::V1::UserIngredients::Recognize", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:base_url) { "/api/v1/user_ingredients/recognize" }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  # テスト用の画像ファイル
  let(:test_image_path) { Rails.root.join("spec/fixtures/files/test_fridge.png") }
  let(:valid_image_file) do
    fixture_file_upload(test_image_path, "image/png")
  end

  describe "POST /api/v1/user_ingredients/recognize" do
    context "認証済みユーザーの場合" do
      context "有効な画像ファイルが提供された場合" do
        let(:mock_recognition_result) do
          {
            success: true,
            recognized_ingredients: [
              { name: "トマト", confidence: 0.95 },
              { name: "玉ねぎ", confidence: 0.88 }
            ],
            conversion_metrics: {
              successful_conversions: 2,
              new_ingredients: 1,
              duplicate_updates: 1
            },
            message: "画像認識が完了しました",
            fridge_image_id: 123
          }
        end

        before do
          # ImageRecognitionServiceをモック化
          mock_service = instance_double(ImageRecognitionService)
          allow(ImageRecognitionService).to receive(:new).and_return(mock_service)
          allow(mock_service).to receive(:recognize_and_convert).and_return(mock_recognition_result)
        end

        it "画像認識が成功し、結果を返す" do
          headers = auth_header_for(user)
          post base_url, params: { image: valid_image_file }, headers: headers

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json["success"]).to be true
          expect(json["recognized_ingredients"]).to be_an(Array)
          expect(json["recognized_ingredients"].size).to eq 2
          expect(json["conversion_metrics"]).to be_a(Hash)
          expect(json["message"]).to eq "画像認識が完了しました"
        end

        it "ImageRecognitionServiceが正しいパラメータで呼び出される" do
          expect(ImageRecognitionService).to receive(:new).with(
            user: user,
            image_source: kind_of(ActionDispatch::Http::UploadedFile)
          )

          headers = auth_header_for(user)
          post base_url, params: { image: valid_image_file }, headers: headers
        end
      end

      context "複数画像が提供された場合" do
        let(:mock_recognition_result) do
          {
            success: true,
            recognized_ingredients: [{ name: "キャベツ", confidence: 0.92 }],
            conversion_metrics: { successful_conversions: 1, new_ingredients: 1 },
            message: "画像認識が完了しました"
          }
        end

        before do
          mock_service = instance_double(ImageRecognitionService)
          allow(ImageRecognitionService).to receive(:new).and_return(mock_service)
          allow(mock_service).to receive(:recognize_and_convert).and_return(mock_recognition_result)
        end

        it "最初の画像のみが処理される" do
          image1 = fixture_file_upload(test_image_path, "image/png")
          image2 = fixture_file_upload(test_image_path, "image/png")

          headers = auth_header_for(user)
          post base_url, params: { images: [ image1, image2 ] }, headers: headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
        end
      end

      context "画像認識サービスでエラーが発生した場合" do
        let(:mock_error_result) do
          {
            success: false,
            message: "画像解析に失敗しました",
            recognized_ingredients: [],
            conversion_metrics: {}
          }
        end

        before do
          mock_service = instance_double(ImageRecognitionService)
          allow(ImageRecognitionService).to receive(:new).and_return(mock_service)
          allow(mock_service).to receive(:recognize_and_convert).and_return(mock_error_result)
        end

        it "エラーレスポンスを返す" do
          headers = auth_header_for(user)
          post base_url, params: { image: valid_image_file }, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)

          json = JSON.parse(response.body)
          expect(json["success"]).to be false
          expect(json["message"]).to eq "画像解析に失敗しました"
          expect(json["recognized_ingredients"]).to eq []
        end
      end

      context "サービスで例外が発生した場合" do
        before do
          mock_service = instance_double(ImageRecognitionService)
          allow(ImageRecognitionService).to receive(:new).and_return(mock_service)
          allow(mock_service).to receive(:recognize_and_convert).and_raise(StandardError, "Unexpected error")
        end

        it "500エラーを返す" do
          headers = auth_header_for(user)
          post base_url, params: { image: valid_image_file }, headers: headers

          expect(response).to have_http_status(:internal_server_error)

          json = JSON.parse(response.body)
          expect(json["success"]).to be false
          expect(json["message"]).to include "画像解析中にエラーが発生しました"
        end
      end
    end

    context "バリデーションエラーの場合" do
      it "画像ファイルが提供されていない場合、400エラーを返す" do
        headers = auth_header_for(user)
        post base_url, params: {}, headers: headers

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["message"]).to eq "画像ファイルが提供されていません"
      end

      it "対応していないファイル形式の場合、400エラーを返す" do
        text_file = fixture_file_upload(Rails.root.join("spec/spec_helper.rb"), "text/plain")

        headers = auth_header_for(user)
        post base_url, params: { image: text_file }, headers: headers

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["message"]).to include "対応していないファイル形式"
      end

      it "ファイルサイズが大きすぎる場合、400エラーを返す" do
        Tempfile.create([ "large_image", ".png" ]) do |tempfile|
          tempfile.binmode
          tempfile.write("0" * (21 * 1024 * 1024)) # 21MB
          tempfile.rewind

          large_file = fixture_file_upload(tempfile.path, "image/png")

          headers = auth_header_for(user)
          post base_url, params: { image: large_file }, headers: headers
        end

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["message"]).to include "ファイルサイズが大きすぎます"
      end

      it "空のファイルの場合、400エラーを返す" do
        Tempfile.create([ "empty_image", ".png" ]) do |tempfile|
          tempfile.binmode
          tempfile.rewind

          empty_file = fixture_file_upload(tempfile.path, "image/png")

          headers = auth_header_for(user)
          post base_url, params: { image: empty_file }, headers: headers
        end

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["message"]).to eq "ファイルが空です"
      end
    end

    context "認証されていないユーザーの場合" do
      it "401エラーを返す" do
        post base_url, params: { image: valid_image_file }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
