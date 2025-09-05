class RecipeConverter
  class ConversionError < StandardError; end

  def initialize
    @ingredient_matcher = IngredientMatcher.new
    @conversion_warnings = []
  end

  # AIレスポンスJSONをRecipeオブジェクトに変換
  def convert(user:, ai_response:, ai_provider:)
    raise ConversionError, 'userが必要です' if user.blank?
    raise ConversionError, 'ai_responseが必要です' if ai_response.blank?
    raise ConversionError, 'ai_providerが必要です' if ai_provider.blank?

    begin
      recipe_data = normalize_recipe_data(ai_response)
      
      Recipe.transaction do
        recipe = create_recipe(user, recipe_data, ai_response, ai_provider)
        create_recipe_ingredients(recipe, recipe_data[:ingredients] || [])
        recipe
      end
    rescue => e
      Rails.logger.error "Recipe conversion failed: #{e.message}"
      Rails.logger.error "AI Response: #{ai_response.inspect}"
      raise ConversionError, "レシピ変換に失敗しました: #{e.message}"
    end
  end

  def conversion_warnings
    @conversion_warnings.dup
  end

  def unmatched_ingredients
    @ingredient_matcher.unmatched_ingredients
  end

  def ambiguous_matches
    @ingredient_matcher.ambiguous_matches
  end

  private

  # AIレスポンスの正規化
  def normalize_recipe_data(ai_response)
    data = ai_response.is_a?(String) ? JSON.parse(ai_response) : ai_response
    
    # 必須フィールドの検証
    validate_required_fields(data)
    
    # データの正規化
    {
      title: normalize_title(data['title']),
      cooking_time: normalize_cooking_time(data),
      difficulty: normalize_difficulty(data['difficulty']),
      servings: normalize_servings(data['servings']),
      steps: normalize_steps(data['steps']),
      ingredients: normalize_ingredients(data['ingredients'] || [])
    }
  end

  def validate_required_fields(data)
    required_fields = ['title', 'steps']
    missing_fields = required_fields.select { |field| data[field].blank? }
    
    if missing_fields.any?
      raise ConversionError, "必須フィールドが不足しています: #{missing_fields.join(', ')}"
    end

    # cooking_timeの検証（複数のキー名に対応）
    cooking_time_keys = ['cooking_time', 'cooking_time_minutes', 'time']
    cooking_time = cooking_time_keys.find { |key| data[key].present? }
    
    unless cooking_time
      raise ConversionError, "調理時間が指定されていません"
    end
  end

  def normalize_title(title)
    return '' if title.blank?
    title.to_s.strip.slice(0, 100)
  end

  def normalize_cooking_time(data)
    # 複数のキー名に対応
    cooking_time_keys = ['cooking_time', 'cooking_time_minutes', 'time']
    cooking_time_value = nil
    
    cooking_time_keys.each do |key|
      if data[key].present?
        cooking_time_value = data[key]
        break
      end
    end

    return 15 if cooking_time_value.blank? # デフォルト値

    # 文字列から数値を抽出（例: "約15分" -> 15）
    if cooking_time_value.is_a?(String)
      extracted = cooking_time_value.gsub(/[^\d]/, '').to_i
      return extracted > 0 ? extracted : 15
    end

    # 数値の場合はそのまま使用（範囲チェック）
    time = cooking_time_value.to_i
    return [[time, 5].max, 480].min # 5分〜8時間の範囲
  end

  def normalize_difficulty(difficulty)
    return nil if difficulty.blank?
    
    case difficulty.to_s.downcase
    when 'easy', '簡単', '⭐', '★'
      'easy'
    when 'medium', '普通', '⭐⭐', '★★'
      'medium'  
    when 'hard', '難しい', '⭐⭐⭐', '★★★'
      'hard'
    else
      add_warning("不明な難易度: #{difficulty}")
      nil
    end
  end

  def normalize_servings(servings)
    return 1 if servings.blank?
    
    # 文字列から数値を抽出
    if servings.is_a?(String)
      extracted = servings.gsub(/[^\d]/, '').to_i
      return extracted > 0 ? [[extracted, 1].max, 20].min : 1
    end
    
    # 数値の場合は範囲チェック
    [[servings.to_i, 1].max, 20].min
  end

  def normalize_steps(steps)
    return [] if steps.blank?
    
    if steps.is_a?(Array)
      # 配列の場合、各要素を正規化
      normalized_steps = steps.map.with_index(1) do |step, index|
        if step.is_a?(Hash)
          # 構造化形式の場合
          {
            'order' => step['order'] || index,
            'text' => step['text']&.to_s&.strip || step['description']&.to_s&.strip || ''
          }
        else
          # 文字列の場合
          {
            'order' => index,
            'text' => step.to_s.strip
          }
        end
      end.reject { |step| step['text'].blank? }
      
      return normalized_steps
    elsif steps.is_a?(String)
      # 文字列の場合、改行や番号で分割を試行
      step_lines = steps.split(/\n|。/).map(&:strip).reject(&:blank?)
      return step_lines.map.with_index(1) do |line, index|
        {
          'order' => index,
          'text' => line.gsub(/^\d+\.?\s*/, '') # 先頭の番号を削除
        }
      end
    end
    
    []
  end

  def normalize_ingredients(ingredients)
    return [] if ingredients.blank? || !ingredients.is_a?(Array)
    
    ingredients.map do |ingredient_data|
      next nil if ingredient_data.blank?
      
      if ingredient_data.is_a?(String)
        # 文字列の場合は名前のみ
        { 'name' => ingredient_data.strip }
      elsif ingredient_data.is_a?(Hash)
        # ハッシュの場合は各フィールドを正規化
        {
          'name' => ingredient_data['name']&.to_s&.strip || ingredient_data['ingredient']&.to_s&.strip,
          'amount' => normalize_ingredient_amount(ingredient_data['amount']),
          'unit' => ingredient_data['unit']&.to_s&.strip,
          'is_optional' => !!ingredient_data['optional'] || !!ingredient_data['is_optional']
        }
      else
        add_warning("不正な食材データ: #{ingredient_data}")
        nil
      end
    end.compact.reject { |ing| ing['name'].blank? }
  end

  def normalize_ingredient_amount(amount)
    return nil if amount.blank?
    
    if amount.is_a?(String)
      # 文字列から数値を抽出（分数や小数に対応）
      cleaned = amount.gsub(/[^\d.\\/]/, '')
      
      if cleaned.include?('/')
        # 分数の場合（例: "1/2"）
        parts = cleaned.split('/')
        return parts[0].to_f / parts[1].to_f if parts.length == 2 && parts[1].to_f > 0
      elsif cleaned.match?(/^\d*\.?\d+$/)
        # 小数や整数の場合
        return cleaned.to_f
      end
    elsif amount.is_a?(Numeric)
      return amount.to_f
    end
    
    nil
  end

  def create_recipe(user, recipe_data, ai_response, ai_provider)
    Recipe.create!(
      user: user,
      title: recipe_data[:title],
      cooking_time: recipe_data[:cooking_time],
      difficulty: recipe_data[:difficulty],
      servings: recipe_data[:servings],
      steps: recipe_data[:steps],
      ai_provider: ai_provider,
      ai_response: ai_response
    )
  end

  def create_recipe_ingredients(recipe, ingredients_data)
    return if ingredients_data.blank?

    # バッチで食材名を取得してマッチング
    ingredient_names = ingredients_data.map { |ing| ing['name'] }.compact.uniq
    matched_ingredients = @ingredient_matcher.find_ingredients_batch(ingredient_names)

    ingredients_data.each do |ingredient_data|
      create_single_recipe_ingredient(recipe, ingredient_data, matched_ingredients)
    end
  end

  def create_single_recipe_ingredient(recipe, ingredient_data, matched_ingredients)
    ingredient_name = ingredient_data['name']
    matched_result = matched_ingredients[ingredient_name]

    recipe_ingredient_attrs = {
      recipe: recipe,
      amount: ingredient_data['amount'],
      unit: ingredient_data['unit'],
      is_optional: ingredient_data['is_optional'] || false
    }

    if matched_result&.dig(:matched)
      # マッチング成功
      recipe_ingredient_attrs[:ingredient] = matched_result[:ingredient]
    else
      # マッチング失敗時のフォールバック
      recipe_ingredient_attrs[:ingredient_name] = ingredient_name
      add_warning("食材マッチング失敗: #{ingredient_name}")
    end

    RecipeIngredient.create!(recipe_ingredient_attrs)
  end

  def add_warning(message)
    @conversion_warnings << {
      message: message,
      timestamp: Time.current
    }
    Rails.logger.warn "[RecipeConverter] #{message}"
  end
end