require 'google/cloud/vision'
require 'base64'
require 'json'

# Vision API解析結果の構造体
GoogleCloudVisionResult = Struct.new(
  :labels,      # [{name:, score:}, ...]
  :objects,     # [{name:, score:, box: [x,y,w,h]}, ...]
  :texts,       # {full_text:, blocks:[{text:, box:[]}, ...]}
  :ingredients  # 正規化後の推定食材一覧
)

class GoogleCloudVisionService
  # 食材の静的マップ（MVPでは日本語のみ対応）
  INGREDIENT_MAPPING = {
    # 野菜
    'tomato' => 'トマト', 'onion' => '玉ねぎ', 'carrot' => '人参', 'potato' => 'じゃがいも',
    'cabbage' => 'キャベツ', 'lettuce' => 'レタス', 'cucumber' => 'きゅうり',
    'broccoli' => 'ブロッコリー', 'spinach' => 'ほうれん草', 'corn' => 'とうもろこし',
    'bell pepper' => 'ピーマン', 'mushroom' => 'きのこ', 'eggplant' => 'なす',
    'radish' => '大根', 'green onion' => 'ネギ',
    
    # 肉類
    'chicken' => '鶏肉', 'beef' => '牛肉', 'pork' => '豚肉', 'fish' => '魚',
    'meat' => '肉', 'seafood' => '魚介類', 'salmon' => 'サケ',
    
    # 乳製品・卵
    'egg' => '卵', 'milk' => '牛乳', 'cheese' => 'チーズ', 'butter' => 'バター',
    'yogurt' => 'ヨーグルト',
    
    # その他
    'bread' => 'パン', 'rice' => 'お米', 'apple' => 'りんご', 'banana' => 'バナナ',
    'orange' => 'オレンジ', 'lemon' => 'レモン'
  }.freeze
  
  # 除外するラベル（食材ではないもの）
  EXCLUDED_LABELS = [
    'food', 'ingredient', 'produce', 'vegetable', 'fruit', 'plant',
    'natural foods', 'whole food', 'tableware', 'bowl', 'plate',
    'cooking', 'kitchen', 'container', 'refrigerator'
  ].freeze

  def initialize(client: nil)
    @client = client || create_vision_client
  end

  # メインの解析メソッド
  def analyze_image(image_bytes, features: %i[label object text])
    return create_error_result('画像データが空です') if image_bytes.nil? || image_bytes.empty?
    
    begin
      # Google Cloud Vision APIに送信
      image = { content: image_bytes }
      feature_requests = build_feature_requests(features)
      
      Rails.logger.info "Vision API Request: features=#{features}, image_size=#{image_bytes.size}"
      
      response = @client.batch_annotate_images(
        requests: [{
          image: image,
          features: feature_requests
        }]
      )
      
      if response.responses.empty?
        return create_error_result('Vision APIからレスポンスが返されませんでした')
      end
      
      annotation = response.responses.first
      
      # エラーチェック
      if annotation.error&.message
        Rails.logger.error "Vision API Error: #{annotation.error.message}"
        return create_error_result("画像解析に失敗しました: #{annotation.error.message}")
      end
      
      # レスポンス解析
      parse_response(annotation, features)
      
    rescue => e
      Rails.logger.error "GoogleCloudVisionService Error: #{e.class}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace&.first(3)&.join(', ')}"
      
      # リトライ可能なエラーかどうかチェック
      if retryable_error?(e)
        raise e # Sidekiqにリトライを委ねる
      else
        return create_error_result('画像解析サービスでエラーが発生しました')
      end
    end
  end

  private

  def create_vision_client
    # 環境変数からBase64エンコードされた認証情報を取得・デコード
    if ENV['GOOGLE_CLOUD_CREDENTIALS']
      begin
        # Base64デコード
        credentials_json = Base64.decode64(ENV['GOOGLE_CLOUD_CREDENTIALS'])
        credentials_hash = JSON.parse(credentials_json)
        
        Rails.logger.info "Using Google Cloud credentials from environment variable"
        
        # 認証情報をファイルとして一時的に作成してクライアントを作成
        require 'tempfile'
        Tempfile.create(['google_credentials', '.json']) do |temp_file|
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
      label: { type: :LABEL_DETECTION, max_results: 20 },
      object: { type: :OBJECT_LOCALIZATION, max_results: 20 },
      text: { type: :TEXT_DETECTION, max_results: 1 }
    }
    
    features.map { |feature| feature_mapping[feature] }.compact
  end

  def parse_response(annotation, features)
    result = GoogleCloudVisionResult.new(
      labels: [],
      objects: [],
      texts: { full_text: '', blocks: [] },
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
      end.select { |label| label[:score] >= 0.6 } # 信頼度0.6以上のみ
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
      end.select { |obj| obj[:score] >= 0.6 }
    end
    
    # テキスト検出結果の処理
    if features.include?(:text) && annotation.text_annotations
      if annotation.text_annotations.any?
        full_text = annotation.text_annotations.first
        result.texts[:full_text] = full_text.description || ''
        
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
    
    Rails.logger.info "Vision API Response: labels=#{result.labels.size}, objects=#{result.objects.size}, ingredients=#{result.ingredients.size}"
    
    result
  end

  def extract_bounding_box(vertices)
    return nil if vertices.empty?
    
    x_coords = vertices.map(&:x)
    y_coords = vertices.map(&:y)
    
    [
      x_coords.min, y_coords.min,
      x_coords.max - x_coords.min, y_coords.max - y_coords.min
    ]
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
        ingredients[ingredient_name] = [current_score + (label[:score] * 0.6), 1.0].min
      end
    end
    
    # オブジェクトから食材抽出（重み: 0.4）
    objects.each do |obj|
      ingredient_name = find_ingredient_name(obj[:name])
      if ingredient_name
        current_score = ingredients[ingredient_name] || 0
        ingredients[ingredient_name] = [current_score + (obj[:score] * 0.4), 1.0].min
      end
    end
    
    # スコア順にソートして上位食材を返す
    ingredients
      .select { |_, score| score >= 0.5 } # 閾値0.5以上
      .sort_by { |_, score| -score }
      .map { |name, score| { name: name, confidence: score.round(3) } }
      .first(10) # 上位10件
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
    error.message&.include?('deadline exceeded') ||
    error.message&.include?('unavailable')
  end

  def create_error_result(message)
    GoogleCloudVisionResult.new(
      labels: [],
      objects: [],
      texts: { full_text: '', blocks: [] },
      ingredients: [{ name: 'エラー', confidence: 0.0, error: message }]
    )
  end
end