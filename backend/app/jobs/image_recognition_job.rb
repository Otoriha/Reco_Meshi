class ImageRecognitionJob < ApplicationJob
  queue_as :default

  # Sidekiqリトライ設定
  retry_on Google::Cloud::DeadlineExceededError, wait: :polynomially_longer, attempts: 3
  retry_on Google::Cloud::UnavailableError, wait: :polynomially_longer, attempts: 3
  retry_on Timeout::Error, wait: :polynomially_longer, attempts: 2

  discard_on Google::Cloud::PermissionDeniedError
  discard_on Google::Cloud::NotFoundError

  def perform(line_user_id, message_id)
    Rails.logger.info "Starting image recognition job: user=#{line_user_id}, message=#{message_id}"

    line_bot_service = LineBotService.new
    vision_service = GoogleCloudVisionService.new
    fridge_image = nil

    begin
      # FridgeImageレコードを作成
      fridge_image = create_fridge_image(line_user_id, message_id)

      # LINEから画像コンテンツを取得
      image_content = fetch_image_content(line_bot_service, message_id)
      unless image_content
        fridge_image.fail_with_error!("画像の取得に失敗しました")
        return send_error_message(line_bot_service, line_user_id, "画像の取得に失敗しました")
      end

      # Vision APIで画像解析
      result = vision_service.analyze_image(image_content, features: %i[label object text])

      # エラーチェック
      if result.ingredients.any? { |ingredient| ingredient[:error] }
        error_ingredient = result.ingredients.find { |ingredient| ingredient[:error] }
        error_message = error_ingredient[:error]
        fridge_image.fail_with_error!(error_message)
        return send_error_message(line_bot_service, line_user_id, error_message)
      end

      # 認識結果をDBに保存
      save_recognition_result(fridge_image, result)

      # 在庫変換処理
      conversion_result = convert_to_inventory(fridge_image)

      # 変換結果をimage_metadataに反映
      update_fridge_image_with_conversion_result(fridge_image, conversion_result)

      # 結果をLINEで送信（変換結果も含む）
      send_recognition_result(line_bot_service, line_user_id, result, conversion_result)

      Rails.logger.info "Image recognition completed successfully: user=#{line_user_id}, ingredients=#{result.ingredients.size}, fridge_image_id=#{fridge_image.id}"

    rescue => e
      Rails.logger.error "ImageRecognitionJob failed: #{e.class}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace&.first(5)&.join(', ')}"

      # FridgeImageのステータスを失敗に更新
      fridge_image&.fail_with_error!("#{e.class}: #{e.message}")

      # 最終失敗時のエラーメッセージ
      send_error_message(line_bot_service, line_user_id, "画像解析中にエラーが発生しました。しばらく経ってから再度お試しください。")
      raise e # Sidekiqのログに残すために再発生
    end
  end

  private

  def create_fridge_image(line_user_id, message_id)
    line_account = LineAccount.find_by(line_user_id: line_user_id)

    fridge_image = FridgeImage.create!(
      user: line_account&.user,
      line_account: line_account,
      line_message_id: message_id,
      status: "processing",
      captured_at: Time.current
    )

    Rails.logger.info "FridgeImage created: id=#{fridge_image.id}, user_id=#{fridge_image.user_id}, line_account_id=#{fridge_image.line_account_id}"
    fridge_image
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

  def fetch_image_content(line_bot_service, message_id)
    begin
      Rails.logger.info "Fetching image content from LINE: message_id=#{message_id}"

      response = line_bot_service.get_message_content(message_id)

      # レスポンスがStringかIOかによって処理を分ける
      content = case response
      when String
                  response
      when IO, StringIO
                  response.read
      else
                  response.body if response.respond_to?(:body)
      end

      if content.nil? || content.empty?
        Rails.logger.error "Empty image content received"
        return nil
      end

      # 画像サイズチェック（20MB制限）
      if content.bytesize > 20.megabytes
        Rails.logger.error "Image too large: #{content.bytesize} bytes"
        return nil
      end

      Rails.logger.info "Image content fetched successfully: size=#{content.bytesize} bytes"
      content

    rescue => e
      Rails.logger.error "Failed to fetch image content: #{e.class}: #{e.message}"
      nil
    end
  end

  def send_recognition_result(line_bot_service, line_user_id, result, conversion_result = nil)
    if result.ingredients.empty?
      # 食材が認識できなかった場合
      message = line_bot_service.create_text_message(
        "🤔 申し訳ありません。\n" \
        "この画像からは食材を認識できませんでした。\n\n" \
        "📷 もう一度、冷蔵庫の中身がはっきり写った写真を送ってください。"
      )
    else
      # 食材が認識できた場合
      ingredients_text = result.ingredients.first(5).map.with_index(1) do |ingredient, index|
        "#{index}. #{ingredient[:name]} (信頼度: #{(ingredient[:confidence] * 100).round}%)"
      end.join("\n")

      # LIFF URLの設定（環境変数から取得）
      liff_id = ENV["REACT_APP_LIFF_ID"] || ENV["LIFF_ID"] || "your-liff-id"
      liff_url = "https://liff.line.me/#{liff_id}"

      # 基本メッセージ
      message_text = "🥬 食材を認識しました！\n\n" \
                     "【認識した食材】\n#{ingredients_text}"

      # 在庫変換結果の追加
      if conversion_result && conversion_result[:success]
        metrics = conversion_result[:metrics]
        if metrics[:successful_conversions] > 0
          message_text += "\n\n✅ 在庫に追加しました：\n"
          message_text += "・新規追加：#{metrics[:new_ingredients]}件\n" if metrics[:new_ingredients] > 0
          message_text += "・数量更新：#{metrics[:duplicate_updates]}件\n" if metrics[:duplicate_updates] > 0
        end
      elsif conversion_result && !conversion_result[:success]
        message_text += "\n\n⚠️ 在庫への自動追加に一部問題がありました"
      end

      message_text += "\n\n📱 在庫リストの確認・編集はこちら\n#{liff_url}"

      message = line_bot_service.create_text_message(message_text)
    end

    # OCRで賞味期限らしきテキストが見つかった場合の追加情報
    if result.texts[:full_text].present?
      date_patterns = extract_date_patterns(result.texts[:full_text])
      if date_patterns.any?
        additional_text = "\n\n💡 賞味期限らしき文字も見つかりました：\n#{date_patterns.first(3).join(', ')}"
        message[:text] += additional_text
      end
    end

    begin
      line_bot_service.push_message(line_user_id, message)
      Rails.logger.info "Recognition result sent successfully to user: #{line_user_id}"
    rescue => e
      Rails.logger.error "Failed to send recognition result: #{e.class}: #{e.message}"
      # プッシュ送信失敗は非同期で再試行
      retry_push_message(line_bot_service, line_user_id, message, attempts: 3)
    end
  end

  def send_error_message(line_bot_service, line_user_id, error_text)
    message = line_bot_service.create_text_message(
      "❌ #{error_text}\n\n" \
      "🔄 再度お試しいただくか、しばらく経ってからお試しください。"
    )

    begin
      line_bot_service.push_message(line_user_id, message)
    rescue => e
      Rails.logger.error "Failed to send error message: #{e.class}: #{e.message}"
    end
  end

  def extract_date_patterns(text)
    # 賞味期限のパターンマッチング（簡易版）
    date_patterns = []

    # 年月日パターン
    patterns = [
      /\d{4}[\/\-年]\d{1,2}[\/\-月]\d{1,2}[日]?/,  # 2024/12/31, 2024-12-31, 2024年12月31日
      /\d{2}[\/\-]\d{1,2}[\/\-]\d{1,2}/,          # 24/12/31
      /\d{1,2}[\/\-]\d{1,2}/                       # 12/31
    ]

    patterns.each do |pattern|
      matches = text.scan(pattern)
      date_patterns.concat(matches.flatten) if matches.any?
    end

    date_patterns.uniq.first(3)
  end

  def retry_push_message(line_bot_service, line_user_id, message, attempts: 3)
    attempts.times do |i|
      sleep(2 ** i) # 指数バックオフ
      begin
        line_bot_service.push_message(line_user_id, message)
        Rails.logger.info "Push message retry succeeded on attempt #{i + 1}"
        return
      rescue => e
        Rails.logger.warn "Push message retry #{i + 1} failed: #{e.message}"
        next if i < attempts - 1
        Rails.logger.error "All push message retries failed"
      end
    end
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
end
