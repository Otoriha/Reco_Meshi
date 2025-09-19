class ImageRecognitionService
  # 画像認識とユーザー在庫変換を同期的に実行するサービス
  # LINE WebhookとWeb APIの両方から利用される共通ロジック

  def initialize(user:, image_source:, fridge_image: nil)
    @user = user
    @image_source = image_source # String(image content) または ActionDispatch::Http::UploadedFile
    @fridge_image = fridge_image
    @vision_service = GoogleCloudVisionService.new
  end

  def recognize_and_convert
    Rails.logger.info "Starting image recognition: user=#{@user.id}, source=#{image_source_type}"

    begin
      # FridgeImageレコードを作成（まだ作成されていない場合）
      @fridge_image ||= create_fridge_image

      # 画像コンテンツを取得
      image_content = extract_image_content
      unless image_content
        @fridge_image.fail_with_error!("画像の取得に失敗しました")
        return error_result("画像の取得に失敗しました")
      end

      # Vision APIで画像解析（30秒タイムアウト）
      vision_result = Timeout.timeout(30) do
        @vision_service.analyze_image(image_content, features: %i[label object text])
      end

      # エラーチェック
      if vision_result.ingredients.any? { |ingredient| ingredient[:error] }
        error_ingredient = vision_result.ingredients.find { |ingredient| ingredient[:error] }
        error_message = error_ingredient[:error]
        @fridge_image.fail_with_error!(error_message)
        return error_result(error_message)
      end

      # 認識結果をDBに保存
      save_recognition_result(@fridge_image, vision_result)

      # 在庫変換処理
      conversion_result = convert_to_inventory(@fridge_image)

      # 変換結果をimage_metadataに反映
      update_fridge_image_with_conversion_result(@fridge_image, conversion_result)

      Rails.logger.info "Image recognition completed successfully: user=#{@user.id}, ingredients=#{vision_result.ingredients.size}, fridge_image_id=#{@fridge_image.id}"

      success_result(vision_result, conversion_result)

    rescue => e
      Rails.logger.error "ImageRecognitionService failed: #{e.class}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace&.first(5)&.join(', ')}"

      # FridgeImageのステータスを失敗に更新
      @fridge_image&.fail_with_error!("#{e.class}: #{e.message}")

      error_result("画像解析中にエラーが発生しました。しばらく経ってから再度お試しください。")
    end
  end

  private

  def image_source_type
    return "content_string" if @image_source.is_a?(String)
    return "uploaded_file" if uploaded_file?(@image_source)

    "unknown"
  end

  def create_fridge_image
    fridge_image = FridgeImage.create!(
      user: @user,
      line_account: @user.line_account, # Web経由の場合はnilが多い（将来のユーザー連携要件に応じて調整）
      line_message_id: nil, # Web APIの場合はnil
      status: "processing",
      captured_at: Time.current
    )

    Rails.logger.info "FridgeImage created: id=#{fridge_image.id}, user_id=#{fridge_image.user_id}"
    fridge_image
  end

  def extract_image_content
    if @image_source.is_a?(String)
      # LINEからの画像コンテンツ（すでに取得済み）
      validate_image_content(@image_source)
    elsif uploaded_file?(@image_source)
      # アップロードファイルから読み取り
      content = @image_source.read
      validate_image_content(content)
    else
      Rails.logger.error "Unsupported image source type: #{@image_source.class}"
      nil
    end
  end

  def validate_image_content(content)
    if content.nil? || content.empty?
      Rails.logger.error "Empty image content received"
      return nil
    end

    # 画像サイズチェック（20MB制限）
    if content.bytesize > 20.megabytes
      Rails.logger.error "Image too large: #{content.bytesize} bytes"
      return nil
    end

    Rails.logger.info "Image content validated successfully: size=#{content.bytesize} bytes"
    content
  end

  def save_recognition_result(fridge_image, vision_result)
    ingredients_data = vision_result.ingredients.map do |ingredient|
      {
        name: ingredient[:name],
        confidence: ingredient[:confidence],
        detected_at: Time.current.iso8601
      }
    end

    metadata = {
      texts: vision_result.texts,
      processing_duration: Time.current - fridge_image.created_at,
      api_version: "v1",
      features_used: %w[label object text]
    }.deep_stringify_keys

    # ラベルやオブジェクトの情報も含める場合
    if vision_result.respond_to?(:labels) && vision_result.labels.present?
      metadata["labels"] = vision_result.labels
    end

    if vision_result.respond_to?(:objects) && vision_result.objects.present?
      metadata["objects"] = vision_result.objects
    end

    fridge_image.complete_with_result!(ingredients_data, metadata)

    Rails.logger.info "Recognition result saved: fridge_image_id=#{fridge_image.id}, ingredients_count=#{ingredients_data.size}"
  end

  def convert_to_inventory(fridge_image)
    return { success: false, message: "User not available" } unless fridge_image.user

    begin
      Rails.logger.info "Starting inventory conversion: fridge_image_id=#{fridge_image.id}, user_id=#{fridge_image.user.id}"

      converter = IngredientConverterService.new(fridge_image)
      result = converter.convert_and_save

      Rails.logger.info "Inventory conversion completed: success=#{result[:success]}, " \
                       "conversions=#{result[:metrics][:successful_conversions]}, " \
                       "new=#{result[:metrics][:new_ingredients]}, " \
                       "updates=#{result[:metrics][:duplicate_updates]}"

      result
    rescue => e
      Rails.logger.error "Unexpected error in inventory conversion: #{e.class}: #{e.message}"
      { success: false, message: "Inventory conversion failed", metrics: {} }
    end
  end

  def update_fridge_image_with_conversion_result(fridge_image, conversion_result)
    return unless fridge_image

    begin
      current_metadata = fridge_image.image_metadata || {}

      # 変換結果を追記
      conversion_metadata = {
        success: conversion_result[:success],
        message: conversion_result[:message],
        metrics: conversion_result[:metrics],
        processed_at: Time.current.iso8601
      }

      # 未マッチ食材の情報も含める（デバッグ用）
      if conversion_result[:unmatched_ingredients]&.any?
        conversion_metadata[:unmatched_ingredients] = conversion_result[:unmatched_ingredients]
      end

      current_metadata["conversion"] = conversion_metadata

      fridge_image.update!(image_metadata: current_metadata)
      Rails.logger.info "Updated fridge_image metadata with conversion result: #{fridge_image.id}"

    rescue => e
      Rails.logger.error "Failed to update fridge_image metadata: #{e.class}: #{e.message}"
    end
  end

  def success_result(vision_result, conversion_result)
    conversion_metrics = (conversion_result[:metrics] || {}).dup
    conversion_metrics[:success] = conversion_result[:success] if conversion_result.key?(:success)

    {
      success: true,
      recognized_ingredients: vision_result.ingredients.map do |ingredient|
        {
          name: ingredient[:name],
          confidence: ingredient[:confidence]
        }
      end,
      conversion_metrics: conversion_metrics,
      message: "画像認識が完了しました",
      fridge_image_id: @fridge_image&.id
    }
  end

  def error_result(message)
    {
      success: false,
      message: message,
      recognized_ingredients: [],
      conversion_metrics: {},
      fridge_image_id: @fridge_image&.id
    }
  end

  def uploaded_file?(source)
    source.is_a?(ActionDispatch::Http::UploadedFile) ||
      (defined?(Rack::Test::UploadedFile) && source.is_a?(Rack::Test::UploadedFile))
  end
end
