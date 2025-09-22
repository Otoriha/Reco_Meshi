require "google/cloud/vision"
require "base64"
require "json"

# Vision API解析結果の構造体
require "google/cloud/vision"
require "base64"
require "json"
require "mini_magick"

GoogleCloudVisionResult = Struct.new(
  :labels,
  :objects,
  :texts,
  :ingredients,
  keyword_init: true
)

class GoogleCloudVisionService
  # 食材の静的マップ（MVPでは日本語のみ対応）
  INGREDIENT_MAPPING = {
    # 野菜
    "tomato" => "トマト", "onion" => "玉ねぎ", "carrot" => "人参", "potato" => "じゃがいも",
    "cabbage" => "キャベツ", "lettuce" => "レタス", "cucumber" => "きゅうり",
    "broccoli" => "ブロッコリー", "spinach" => "ほうれん草", "corn" => "とうもろこし",
    "bell pepper" => "ピーマン", "mushroom" => "きのこ", "eggplant" => "なす",
    "radish" => "大根", "green onion" => "ネギ",

    # 肉類
    "chicken" => "鶏肉", "beef" => "牛肉", "pork" => "豚肉", "fish" => "魚",
    "meat" => "肉", "seafood" => "魚介類", "salmon" => "サケ",

    # 乳製品・卵
    "egg" => "卵", "milk" => "牛乳", "cheese" => "チーズ", "butter" => "バター",
    "yogurt" => "ヨーグルト",

    # その他
    "bread" => "パン", "rice" => "お米", "apple" => "りんご", "banana" => "バナナ",
    "orange" => "オレンジ", "lemon" => "レモン"
  }.freeze

  # 除外するラベル（食材ではないもの）
  EXCLUDED_LABELS = [
    "food", "ingredient", "produce", "vegetable", "fruit", "plant",
    "natural foods", "whole food", "tableware", "bowl", "plate",
    "cooking", "kitchen", "container", "refrigerator"
  ].freeze

  def initialize(client: nil)
    @client = client || create_vision_client
    @config = Rails.configuration.x.vision
    @api_call_count = 0
  end

  # メインの解析メソッド
  def analyze_image(image_bytes, features: %i[label object text])
    return create_error_result("画像データが空です") if image_bytes.nil? || image_bytes.empty?

    begin
      start_time = Time.current
      @api_call_count = 0
      
      # Google Cloud Vision APIに送信
      image = { content: image_bytes }
      feature_requests = build_feature_requests(features)

      Rails.logger.info "Vision API Request: features=#{features}, image_size=#{image_bytes.size}"

      response = @client.batch_annotate_images(
        requests: [ {
          image: image,
          features: feature_requests
        } ]
      )
      @api_call_count += 1

      if response.responses.empty?
        return create_error_result("Vision APIからレスポンスが返されませんでした")
      end

      annotation = response.responses.first

      # エラーチェック
      if annotation.error&.message
        Rails.logger.error "Vision API Error: #{annotation.error.message}"
        return create_error_result("画像解析に失敗しました: #{annotation.error.message}")
      end

      # レスポンス解析
      result = parse_response(annotation, features)

      # BBoxクロップ再判定の実行（フラグが有効かつオブジェクトが存在する場合）
      if @config.enable_crop_reeval && result.objects.any? && @api_call_count < @config.api_max_calls
        crop_and_reanalyze(image_bytes, result)
      end

      # 処理時間計算
      processing_ms = ((Time.current - start_time) * 1000).round

      # メトリクス記録
      result.define_singleton_method(:metadata) do
        {
          features_used: features,
          label_min_score: @config.label_min_score,
          object_min_score: @config.object_min_score,
          ingredient_threshold: @config.ingredient_threshold,
          max_results: @config.max_results,
          num_objects: result.objects.size,
          num_crops_analyzed: @config.enable_crop_reeval ? [@config.max_crops, result.objects.size].min : 0,
          api_calls: @api_call_count,
          processing_ms: processing_ms,
          vision_config_version: '2.0',
          crop_reeval_enabled: @config.enable_crop_reeval,
          image_size_bytes: image_bytes.size
        }
      end

      # 最終メトリクスログ
      Rails.logger.info "Vision API Analysis Complete: " +
        "api_calls=#{@api_call_count}, " +
        "ingredients=#{result.ingredients.size}, " +
        "processing_ms=#{processing_ms}, " +
        "crop_reeval=#{@config.enable_crop_reeval}, " +
        "objects=#{result.objects.size}"

      result

    rescue => e
      Rails.logger.error "GoogleCloudVisionService Error: #{e.class}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace&.first(3)&.join(', ')}"

      # リトライ可能なエラーかどうかチェック
      if retryable_error?(e)
        raise e # Sidekiqにリトライを委ねる
      else
        create_error_result("画像解析サービスでエラーが発生しました")
      end
    end
  end

  private

  def create_vision_client
    # 環境変数からBase64エンコードされた認証情報を取得・デコード
    if ENV["GOOGLE_CLOUD_CREDENTIALS"]
      begin
        # Base64デコード
        credentials_json = Base64.decode64(ENV["GOOGLE_CLOUD_CREDENTIALS"])
        credentials_hash = JSON.parse(credentials_json)

        Rails.logger.info "Using Google Cloud credentials from environment variable"

        # 認証情報をファイルとして一時的に作成してクライアントを作成
        require "tempfile"
        Tempfile.create([ "google_credentials", ".json" ]) do |temp_file|
          temp_file.write(credentials_json)
          temp_file.rewind

          Google::Cloud::Vision.image_annotator do |config|
            config.credentials = temp_file.path
          end
        end
      rescue => e
        Rails.logger.error "Failed to parse Google Cloud credentials: #{e.message}"
        raise "Google Cloud認証情報の設定に失敗しました: #{e.message}"
      end
    else
      Rails.logger.info "Using default Google Cloud credentials"
      Google::Cloud::Vision.image_annotator
    end
  end

  def build_feature_requests(features)
    feature_mapping = {
      label: { type: :LABEL_DETECTION, max_results: @config.max_results },
      object: { type: :OBJECT_LOCALIZATION, max_results: @config.max_results },
      text: { type: :TEXT_DETECTION, max_results: 1 }
    }

    features.map { |feature| feature_mapping[feature] }.compact
  end

  def parse_response(annotation, features)
    result = GoogleCloudVisionResult.new(
      labels: [],
      objects: [],
      texts: { full_text: "", blocks: [] },
      ingredients: []
    )

    # ラベル検出結果の処理
    if features.include?(:label) && annotation.label_annotations
      result.labels = annotation.label_annotations.map do |label|
        {
          name: label.description.downcase,
          score: label.score.round(3),
          locale: label.locale
        }
      end.select { |label| label[:score] >= @config.label_min_score }
    end

    # オブジェクト検出結果の処理
    if features.include?(:object) && annotation.localized_object_annotations
      result.objects = annotation.localized_object_annotations.map do |obj|
        vertices = obj.bounding_poly.normalized_vertices
        box = extract_bounding_box(vertices) if vertices.any?

        {
          name: obj.name.downcase,
          score: obj.score.round(3),
          box: box
        }
      end.select { |obj| obj[:score] >= @config.object_min_score }
    end

    # テキスト検出結果の処理
    if features.include?(:text) && annotation.text_annotations
      if annotation.text_annotations.any?
        full_text = annotation.text_annotations.first
        result.texts[:full_text] = full_text.description || ""

        # 個別のテキストブロック
        result.texts[:blocks] = annotation.text_annotations[1..-1]&.map do |text|
          vertices = text.bounding_poly.vertices
          box = extract_text_bounding_box(vertices) if vertices.any?

          {
            text: text.description,
            box: box
          }
        end || []
      end
    end

    # 食材候補の抽出と正規化
    result.ingredients = extract_ingredients(result.labels, result.objects)

    Rails.logger.info "Vision API Response: labels=#{result.labels.size}, objects=#{result.objects.size}, ingredients=#{result.ingredients.size}, " +
      "config: label_min=#{@config.label_min_score}, object_min=#{@config.object_min_score}, max_results=#{@config.max_results}"

    result
  end

  def extract_bounding_box(vertices)
    return nil if vertices.empty?

    x_coords = vertices.map(&:x)
    y_coords = vertices.map(&:y)

    {
      x: x_coords.min,
      y: y_coords.min,
      width: x_coords.max - x_coords.min,
      height: y_coords.max - y_coords.min
    }
  end

  def extract_text_bounding_box(vertices)
    return nil if vertices.empty?

    x_coords = vertices.map(&:x)
    y_coords = vertices.map(&:y)

    [
      x_coords.min, y_coords.min,
      x_coords.max - x_coords.min, y_coords.max - y_coords.min
    ]
  end

  def extract_ingredients(labels, objects)
    ingredients = {}

    # ラベルから食材抽出（重み: 0.6）
    labels.each do |label|
      next if EXCLUDED_LABELS.include?(label[:name])

      ingredient_name = find_ingredient_name(label[:name])
      if ingredient_name
        current_score = ingredients[ingredient_name] || 0
        ingredients[ingredient_name] = [ current_score + (label[:score] * 0.6), 1.0 ].min
      end
    end

    # オブジェクトから食材抽出（重み: 0.4）
    objects.each do |obj|
      ingredient_name = find_ingredient_name(obj[:name])
      if ingredient_name
        current_score = ingredients[ingredient_name] || 0
        ingredients[ingredient_name] = [ current_score + (obj[:score] * 0.4), 1.0 ].min
      end
    end

    # スコア順にソートして上位食材を返す
    ingredients
      .select { |_, score| score >= @config.ingredient_threshold }
      .sort_by { |_, score| -score }
      .map { |name, score| { name: name, confidence: score.round(3) } }
      .first(15) # 上位15件
  end

  def find_ingredient_name(detected_name)
    # 完全一致
    return INGREDIENT_MAPPING[detected_name] if INGREDIENT_MAPPING[detected_name]

    # 部分一致（キーワード含む）
    INGREDIENT_MAPPING.each do |key, value|
      return value if detected_name.include?(key) || key.include?(detected_name)
    end

    # 日本語での直接マッチング（ひらがな・カタカナ・漢字）
    japanese_ingredients = INGREDIENT_MAPPING.values
    japanese_ingredients.find { |ingredient| detected_name.include?(ingredient) }
  end

  def retryable_error?(error)
    error.is_a?(Google::Cloud::DeadlineExceededError) ||
    error.is_a?(Google::Cloud::UnavailableError) ||
    error.message&.include?("deadline exceeded") ||
    error.message&.include?("unavailable")
  end

  def create_error_result(message)
    GoogleCloudVisionResult.new(
      labels: [],
      objects: [],
      texts: { full_text: "", blocks: [] },
      ingredients: [ { name: "エラー", confidence: 0.0, error: message } ]
    )
  end

  private

  # BBoxクロップ再判定のメイン処理
  def crop_and_reanalyze(original_bytes, result)
    return unless @config.enable_crop_reeval

    # オブジェクトをスコア順でソートし、上位N個を選択
    crops_to_analyze = result.objects
      .sort_by { |obj| -obj[:score] }
      .first(@config.max_crops)

    Rails.logger.info "Starting crop reanalysis: #{crops_to_analyze.size} crops"

    crops_to_analyze.each_with_index do |obj, index|
      break if @api_call_count >= @config.api_max_calls

      begin
        crop_bytes = crop_image_bytes(original_bytes, obj[:box])
        next unless crop_bytes

        # クロップ画像をLABEL_DETECTIONで解析
        crop_labels = analyze_crop(crop_bytes)
        merge_crop_results(result, crop_labels, weight: 0.3)

        Rails.logger.debug "Crop #{index + 1} analyzed: #{crop_labels.size} labels found"

      rescue => e
        Rails.logger.warn "Failed to process crop #{index + 1}: #{e.message}"
      end
    end

    # 食材リストを再構築
    result.ingredients = extract_ingredients(result.labels, result.objects)
  end

  # 画像をクロップする
  def crop_image_bytes(image_bytes, bbox)
    return nil unless bbox && bbox[:x] && bbox[:y] && bbox[:width] && bbox[:height]

    begin
      image = MiniMagick::Image.read(image_bytes)
      
      # 正規化座標をピクセル座標に変換
      x = (bbox[:x] * image.width).to_i
      y = (bbox[:y] * image.height).to_i
      width = (bbox[:width] * image.width).to_i
      height = (bbox[:height] * image.height).to_i

      # 範囲チェック
      x = [[x, 0].max, image.width - 1].min
      y = [[y, 0].max, image.height - 1].min
      width = [width, image.width - x].min
      height = [height, image.height - y].min

      # 最小サイズチェック
      return nil if width < 10 || height < 10

      # クロップ実行
      image.crop("#{width}x#{height}+#{x}+#{y}")
      image.to_blob

    rescue => e
      Rails.logger.warn "Image cropping failed: #{e.message}"
      nil
    end
  end

  # クロップ画像を解析
  def analyze_crop(crop_bytes)
    return [] unless crop_bytes

    begin
      image = { content: crop_bytes }
      features = [{ type: :LABEL_DETECTION, max_results: 10 }]

      response = @client.batch_annotate_images(
        requests: [{
          image: image,
          features: features
        }]
      )
      @api_call_count += 1

      return [] if response.responses.empty?

      annotation = response.responses.first
      return [] if annotation.error&.message

      # ラベルを抽出（低い閾値で）
      annotation.label_annotations.map do |label|
        {
          name: label.description.downcase,
          score: label.score.round(3),
          locale: label.locale
        }
      end.select { |label| label[:score] >= 0.3 } # クロップでは低い閾値

    rescue => e
      Rails.logger.warn "Crop analysis failed: #{e.message}"
      []
    end
  end

  # クロップ結果を既存の結果にマージ
  def merge_crop_results(result, crop_labels, weight: 0.3)
    crop_labels.each do |crop_label|
      # 既存のラベルを探す
      existing_label = result.labels.find { |l| l[:name] == crop_label[:name] }
      
      if existing_label
        # スコアを加重平均で更新（最大1.0まで）
        existing_label[:score] = [existing_label[:score] + (crop_label[:score] * weight), 1.0].min
      else
        # 新しいラベルとして追加
        result.labels << {
          name: crop_label[:name],
          score: (crop_label[:score] * weight).round(3),
          locale: crop_label[:locale]
        }
      end
    end

    # スコア順にソート
    result.labels.sort_by! { |label| -label[:score] }
  end
end
