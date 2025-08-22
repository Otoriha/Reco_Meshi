class IngredientConverter
  class ConversionError < StandardError; end

  # カテゴリ別デフォルト値
  CATEGORY_DEFAULTS = {
    'vegetables' => { quantity: 1, unit: '個' },
    'meat' => { quantity: 200, unit: 'g' },
    'fish' => { quantity: 1, unit: '尾' },
    'dairy' => { quantity: 1, unit: '個' },
    'seasonings' => { quantity: 1, unit: '本' },
    'others' => { quantity: 1, unit: '個' }
  }.freeze

  # 特殊ケース（食材名による個別設定）
  SPECIAL_UNITS = {
    '卵' => { quantity: 10, unit: '個' },
    'たまご' => { quantity: 10, unit: '個' },
    'ほうれん草' => { quantity: 1, unit: '束' },
    'キャベツ' => { quantity: 1, unit: '玉' },
    'レタス' => { quantity: 1, unit: '玉' },
    '牛乳' => { quantity: 1000, unit: 'ml' },
    'パン' => { quantity: 6, unit: '枚' },
    'チーズ' => { quantity: 100, unit: 'g' },
    'バター' => { quantity: 200, unit: 'g' },
    'ヨーグルト' => { quantity: 400, unit: 'g' },
    'お米' => { quantity: 2000, unit: 'g' },
    'りんご' => { quantity: 3, unit: '個' },
    'バナナ' => { quantity: 5, unit: '本' },
    'トマト' => { quantity: 3, unit: '個' },
    'きのこ' => { quantity: 100, unit: 'g' }
  }.freeze

  # カテゴリ別デフォルト賞味期限（日数）
  EXPIRY_DEFAULTS = {
    'vegetables' => 7,
    'meat' => 3,
    'fish' => 2,
    'dairy' => 10,
    'seasonings' => 365,
    'others' => 14
  }.freeze

  # 認識信頼度の最小閾値
  MIN_CONFIDENCE = 0.5

  def initialize(user:, fridge_image:)
    @user = user
    @fridge_image = fridge_image
    @matcher = IngredientMatcher.new
    @conversion_metrics = {
      total_recognized: 0,
      successful_conversions: 0,
      skipped_low_confidence: 0,
      unmatched_ingredients: 0,
      duplicate_updates: 0,
      new_ingredients: 0,
      errors: []
    }
  end

  def convert_and_save
    return conversion_result(false, 'Recognition data not available') unless valid_recognition_data?

    ActiveRecord::Base.transaction do
      @conversion_metrics[:total_recognized] = recognized_ingredients.size

      recognized_ingredients.each do |recognized_ingredient|
        process_single_ingredient(recognized_ingredient)
      end

      log_conversion_metrics
      conversion_result(true, 'Conversion completed successfully')
    end

  rescue => e
    Rails.logger.error "IngredientConverter failed: #{e.class}: #{e.message}"
    @conversion_metrics[:errors] << "#{e.class}: #{e.message}"
    conversion_result(false, e.message)
  end

  def conversion_metrics
    @conversion_metrics.dup
  end

  private

  def valid_recognition_data?
    @fridge_image.has_ingredients? && recognized_ingredients.is_a?(Array)
  end

  def recognized_ingredients
    @recognized_ingredients ||= @fridge_image.recognized_ingredients
  end

  def process_single_ingredient(recognized_ingredient)
    name = recognized_ingredient['name']
    confidence = recognized_ingredient['confidence'].to_f

    # 信頼度チェック
    if confidence < MIN_CONFIDENCE
      @conversion_metrics[:skipped_low_confidence] += 1
      Rails.logger.debug "Skipping low confidence ingredient: #{name} (#{confidence})"
      return
    end

    # 食材マッチング
    match_result = @matcher.find_ingredient(name)
    
    if match_result.nil?
      @conversion_metrics[:unmatched_ingredients] += 1
      Rails.logger.info "Unmatched ingredient: #{name}"
      return
    end

    ingredient = match_result[:ingredient]
    match_confidence = match_result[:confidence]

    # 重複チェックと処理
    existing_user_ingredient = find_existing_user_ingredient(ingredient)
    
    if existing_user_ingredient
      update_existing_ingredient(existing_user_ingredient, recognized_ingredient, match_confidence)
      @conversion_metrics[:duplicate_updates] += 1
    else
      create_new_user_ingredient(ingredient, recognized_ingredient, match_confidence)
      @conversion_metrics[:new_ingredients] += 1
    end

    @conversion_metrics[:successful_conversions] += 1

  rescue => e
    Rails.logger.error "Failed to process ingredient #{name}: #{e.message}"
    @conversion_metrics[:errors] << "#{name}: #{e.message}"
    # 個別失敗は継続処理
  end

  def find_existing_user_ingredient(ingredient)
    @user.user_ingredients
          .joins(:ingredient)
          .where(ingredient: ingredient, status: 'available')
          .first
  end

  def update_existing_ingredient(existing_ingredient, recognized_data, match_confidence)
    # 既存の食材の数量を増加
    estimated_quantity = estimate_quantity(existing_ingredient.ingredient, recognized_data)
    new_quantity = existing_ingredient.quantity + estimated_quantity

    existing_ingredient.update!(
      quantity: new_quantity,
      fridge_image: @fridge_image,
      updated_at: Time.current
    )

    Rails.logger.info "Updated existing ingredient: #{existing_ingredient.ingredient.name} " \
                     "(#{existing_ingredient.quantity - estimated_quantity} -> #{new_quantity})"
  end

  def create_new_user_ingredient(ingredient, recognized_data, match_confidence)
    quantity = estimate_quantity(ingredient, recognized_data)
    expiry_date = estimate_expiry_date(ingredient)

    user_ingredient = @user.user_ingredients.create!(
      ingredient: ingredient,
      quantity: quantity,
      status: 'available',
      expiry_date: expiry_date,
      fridge_image: @fridge_image,
      created_at: Time.current,
      updated_at: Time.current
    )

    Rails.logger.info "Created new user ingredient: #{ingredient.name} " \
                     "(#{quantity}#{ingredient.unit}, expires: #{expiry_date})"
    
    user_ingredient
  end

  def estimate_quantity(ingredient, recognized_data)
    ingredient_name = ingredient.name

    # 特殊ケース優先
    if SPECIAL_UNITS.key?(ingredient_name)
      return SPECIAL_UNITS[ingredient_name][:quantity]
    end

    # カテゴリ別デフォルト
    category = ingredient.category || 'others'
    CATEGORY_DEFAULTS[category][:quantity]
  end

  def estimate_expiry_date(ingredient)
    category = ingredient.category || 'others'
    days_to_expire = EXPIRY_DEFAULTS[category]
    
    Date.current + days_to_expire.days
  end

  def log_conversion_metrics
    metrics = @conversion_metrics
    Rails.logger.info "Ingredient conversion completed for user #{@user.id}:"
    Rails.logger.info "  Total recognized: #{metrics[:total_recognized]}"
    Rails.logger.info "  Successful conversions: #{metrics[:successful_conversions]}"
    Rails.logger.info "  New ingredients: #{metrics[:new_ingredients]}"
    Rails.logger.info "  Duplicate updates: #{metrics[:duplicate_updates]}"
    Rails.logger.info "  Skipped (low confidence): #{metrics[:skipped_low_confidence]}"
    Rails.logger.info "  Unmatched: #{metrics[:unmatched_ingredients]}"
    Rails.logger.info "  Errors: #{metrics[:errors].size}"

    # 未マッチ食材の記録
    unmatched = @matcher.unmatched_ingredients
    if unmatched.any?
      Rails.logger.info "Unmatched ingredients for future improvement:"
      unmatched.each { |ing| Rails.logger.info "  - #{ing[:name]} (#{ing[:normalized_name]})" }
    end
  end

  def conversion_result(success, message)
    {
      success: success,
      message: message,
      metrics: @conversion_metrics.dup,
      unmatched_ingredients: @matcher.unmatched_ingredients
    }
  end
end