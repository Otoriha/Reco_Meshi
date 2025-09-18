class IngredientConverterService
  # ConversionError例外クラスは未使用のため削除

  # 設定値（ENV から取得可能）
  MIN_CONFIDENCE = ENV.fetch("INGREDIENT_MIN_CONFIDENCE", "0.5").to_f

  # カテゴリ別デフォルト値（quantity: Decimal, unit: String）
  CATEGORY_DEFAULTS = {
    "vegetables" => { quantity: 1.0, unit: "個" },
    "meat" => { quantity: 200.0, unit: "g" },
    "fish" => { quantity: 1.0, unit: "尾" },
    "dairy" => { quantity: 1.0, unit: "個" },
    "seasonings" => { quantity: 1.0, unit: "本" },
    "others" => { quantity: 1.0, unit: "個" }
  }.freeze

  # 特殊ケース（食材名による個別設定）
  SPECIAL_UNITS = {
    "卵" => { quantity: 10.0, unit: "個" },
    "たまご" => { quantity: 10.0, unit: "個" },
    "ほうれん草" => { quantity: 1.0, unit: "束" },
    "キャベツ" => { quantity: 1.0, unit: "玉" },
    "レタス" => { quantity: 1.0, unit: "玉" },
    "牛乳" => { quantity: 1000.0, unit: "ml" },
    "パン" => { quantity: 6.0, unit: "枚" },
    "チーズ" => { quantity: 100.0, unit: "g" },
    "バター" => { quantity: 200.0, unit: "g" },
    "ヨーグルト" => { quantity: 400.0, unit: "g" },
    "お米" => { quantity: 2000.0, unit: "g" },
    "りんご" => { quantity: 3.0, unit: "個" },
    "バナナ" => { quantity: 5.0, unit: "本" },
    "トマト" => { quantity: 3.0, unit: "個" },
    "きのこ" => { quantity: 100.0, unit: "g" }
  }.freeze

  # カテゴリ別デフォルト賞味期限（日数）
  EXPIRY_DEFAULTS = {
    "vegetables" => 7,
    "meat" => 3,
    "fish" => 2,
    "dairy" => 10,
    "seasonings" => 365,
    "others" => 14
  }.freeze

  # 重複統合キー: user_id, ingredient_id, unit, expiry_date, status=available
  def initialize(input_source)
    case input_source
    when FridgeImage
      @fridge_image = input_source
      @user = input_source.user
      @recognized_ingredients = input_source.recognized_ingredients
    when Hash
      @recognized_ingredients = input_source[:recognized_ingredients] || []
      @user = input_source[:user]
      @fridge_image = input_source[:fridge_image]
    else
      raise ArgumentError, "Invalid input source. Expected FridgeImage or Hash"
    end

    @matcher = IngredientMatcher.new
    @conversion_metrics = initialize_metrics
  end

  def convert_and_save
    return conversion_result(false, "User not available") unless @user
    return conversion_result(false, "Recognition data not available") unless valid_recognition_data?

    # 冪等性の担保：既に処理済みかチェック
    if already_processed?
      Rails.logger.info "Skipping already processed fridge_image: #{@fridge_image&.id}"
      return conversion_result(true, "Already processed", skip_processed: true)
    end

    @conversion_metrics[:total_recognized] = @recognized_ingredients.size

    # バルク処理用のデータ準備
    ingredient_candidates = prepare_ingredient_candidates

    ActiveRecord::Base.transaction do
      # 性能配慮：バルクでの照合とマッピング
      ingredient_mapping = build_ingredient_mapping(ingredient_candidates)

      # 既存在庫の一括取得（N+1回避）
      existing_ingredients_map = fetch_existing_ingredients(ingredient_mapping.keys)

      # バッチ処理でUserIngredientを作成/更新
      process_ingredients_batch(ingredient_mapping, existing_ingredients_map)

      # 処理完了（冪等性は既存レコードの存在で判定）

      log_conversion_metrics
      conversion_result(true, "Conversion completed successfully")
    end

  rescue ActiveRecord::Deadlocked, ActiveRecord::RecordNotUnique => e
    # 一時的なDB競合の場合は短時間でリトライ
    Rails.logger.warn "DB conflict in ingredient conversion: #{e.message}, retrying..."
    sleep(0.1)
    retry_once ||= true
    if retry_once
      retry_once = false
      retry
    else
      @conversion_metrics[:errors] << "DB conflict: #{e.message}"
      conversion_result(false, "Database conflict occurred")
    end
  rescue => e
    Rails.logger.error "IngredientConverterService failed: #{e.class}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace&.first(3)&.join(', ')}"
    @conversion_metrics[:errors] << "#{e.class}: #{e.message}"
    conversion_result(false, e.message)
  end

  def conversion_metrics
    @conversion_metrics.dup
  end

  private

  def initialize_metrics
    {
      total_recognized: 0,
      successful_conversions: 0,
      skipped_low_confidence: 0,
      unmatched_ingredients: 0,
      duplicate_updates: 0,
      new_ingredients: 0,
      skipped_processed: 0,
      errors: []
    }
  end

  def valid_recognition_data?
    return false unless @recognized_ingredients.is_a?(Array)
    return false if @recognized_ingredients.empty?

    # 入力バリデーション: 形式不正や空配列は警告ログ出力してスキップ
    @recognized_ingredients.each do |ingredient_data|
      unless ingredient_data.is_a?(Hash) && ingredient_data["name"].present?
        Rails.logger.warn "Invalid ingredient data format: #{ingredient_data.inspect}"
        return false
      end
    end

    true
  end

  def already_processed?
    return false unless @fridge_image

    # 既存のカラムで代用：source_image_idが一致するUserIngredientが存在するかチェック
    @user.user_ingredients.where(fridge_image: @fridge_image).exists?
  end

  def prepare_ingredient_candidates
    candidates = []

    @recognized_ingredients.each do |recognized_ingredient|
      name = recognized_ingredient["name"]&.to_s&.strip
      confidence = recognized_ingredient["confidence"].to_f

      next if name.blank?

      if confidence < MIN_CONFIDENCE
        @conversion_metrics[:skipped_low_confidence] += 1
        Rails.logger.debug "Skipping low confidence ingredient: #{name} (#{confidence})"
        next
      end

      candidates << {
        original_name: name,
        confidence: confidence,
        data: recognized_ingredient
      }
    end

    candidates
  end

  def build_ingredient_mapping(candidates)
    return {} if candidates.empty?

    names = candidates.map { |c| c[:original_name] }
    name_to_result = @matcher.find_ingredients_batch(names) # 返値: Hash

    mapping = {}
    candidates.each do |candidate|
      match_result = name_to_result[candidate[:original_name]]
      if match_result
        mapping[match_result[:ingredient]] = {
          candidate: candidate,
          match_confidence: match_result[:confidence]
        }
      else
        @conversion_metrics[:unmatched_ingredients] += 1
      end
    end

    mapping
  end

  def fetch_existing_ingredients(ingredients)
    return {} if ingredients.empty?

    # N+1回避：一括でingredientを含めて既存在庫を取得
    all_existing = @user.user_ingredients
                        .includes(:ingredient)
                        .where(ingredient_id: ingredients.map(&:id), status: "available")
                        .to_a

    # 食材ごとにグループ化してさらにunit/expiry_dateでグループ化
    existing_map = {}
    all_existing.group_by(&:ingredient).each do |ingredient, user_ingredients|
      existing_map[ingredient] = group_by_unit_and_expiry(user_ingredients)
    end

    existing_map
  end

  def group_by_unit_and_expiry(user_ingredients)
    # 期限なしを優先するため、まずnil期限でグループ化
    grouped = user_ingredients.group_by { |ui| [ ui.ingredient.unit, ui.expiry_date ] }

    # デバッグ用ログ
    grouped.each do |key, uis|
      unit, expiry = key
      Rails.logger.debug "Grouped existing: unit=#{unit}, expiry=#{expiry}, count=#{uis.size}"
    end

    grouped
  end

  def process_ingredients_batch(ingredient_mapping, existing_ingredients_map)
    new_user_ingredients = []
    update_operations = []

    ingredient_mapping.each do |ingredient, mapping_data|
      candidate = mapping_data[:candidate]

      begin
        quantity_unit = determine_quantity_and_unit(ingredient, candidate)
        existing_groups = existing_ingredients_map[ingredient] || {}

        # 期限なし在庫との統合ロジック：優先順位
        # 1. 同一unitかつnil期限の既存在庫を優先的にマッチ
        # 2. マッチしたら加算し、既存のexpiry_dateをカテゴリ既定で更新
        # 3. nil期限の既存在庫がない場合は新規作成

        nil_expiry_key = [ quantity_unit[:unit], nil ]
        nil_expiry_ingredients = existing_groups[nil_expiry_key] || []

        if nil_expiry_ingredients.any?
          # nil期限の既存在庫に加算し、既定期限で更新
          target_ingredient = nil_expiry_ingredients.first
          new_quantity = target_ingredient.quantity + quantity_unit[:quantity]
          estimated_expiry = estimate_expiry_date(ingredient)

          update_operations << {
            user_ingredient: target_ingredient,
            new_quantity: new_quantity,
            new_expiry_date: estimated_expiry # 既定期限で更新
          }

          @conversion_metrics[:duplicate_updates] += 1
          Rails.logger.debug "Updated nil expiry ingredient: #{ingredient.name} -> #{new_quantity}#{quantity_unit[:unit]}, expiry: #{estimated_expiry}"

        else
          # 期限ありの既存在庫をチェック
          estimated_expiry = estimate_expiry_date(ingredient)
          expiry_key = [ quantity_unit[:unit], estimated_expiry ]
          existing_ingredients = existing_groups[expiry_key] || []

          if existing_ingredients.any?
            # 同一unit・同一期限の既存在庫に加算
            target_ingredient = existing_ingredients.first
            new_quantity = target_ingredient.quantity + quantity_unit[:quantity]

            update_operations << {
              user_ingredient: target_ingredient,
              new_quantity: new_quantity
            }

            @conversion_metrics[:duplicate_updates] += 1
            Rails.logger.debug "Updated existing ingredient: #{ingredient.name} -> #{new_quantity}#{quantity_unit[:unit]}, expiry: #{estimated_expiry}"

          else
            # 新規作成
            new_user_ingredients << build_user_ingredient_attributes(
              ingredient, quantity_unit, estimated_expiry, candidate
            )

            @conversion_metrics[:new_ingredients] += 1
            Rails.logger.debug "Created new ingredient: #{ingredient.name} -> #{quantity_unit[:quantity]}#{quantity_unit[:unit]}, expiry: #{estimated_expiry}"
          end
        end

        @conversion_metrics[:successful_conversions] += 1

      rescue => e
        Rails.logger.error "Failed to process ingredient #{candidate[:original_name]}: #{e.message}"
        @conversion_metrics[:errors] << "#{candidate[:original_name]}: #{e.message}"
      end
    end

    # バルク処理実行
    execute_bulk_operations(new_user_ingredients, update_operations)
  end

  def execute_bulk_operations(new_user_ingredients, update_operations)
    # 新規作成（insert_all使用：一意制約の問題を回避）
    if new_user_ingredients.any?
      UserIngredient.insert_all(new_user_ingredients)
      Rails.logger.info "Bulk inserted #{new_user_ingredients.size} new user ingredients"
    end

    # 数量・期限更新（個別更新）
    update_operations.each do |op|
      update_attrs = {
        quantity: op[:new_quantity],
        fridge_image: @fridge_image,
        updated_at: Time.current
      }

      # 期限更新がある場合は追加
      if op[:new_expiry_date]
        update_attrs[:expiry_date] = op[:new_expiry_date]
      end

      op[:user_ingredient].update!(update_attrs)
    end

    if update_operations.any?
      Rails.logger.info "Updated #{update_operations.size} existing user ingredients"
    end
  end

  def build_user_ingredient_attributes(ingredient, quantity_unit, expiry_date, candidate)
    {
      user_id: @user.id,
      ingredient_id: ingredient.id,
      quantity: quantity_unit[:quantity],
      status: "available",
      expiry_date: expiry_date,
      fridge_image_id: @fridge_image&.id,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def determine_quantity_and_unit(ingredient, candidate)
    ingredient_name = ingredient.name

    # 1. 特殊ケース優先
    if SPECIAL_UNITS.key?(ingredient_name)
      return SPECIAL_UNITS[ingredient_name].dup
    end

    # 2. カテゴリ別デフォルト
    category = ingredient.category || "others"
    defaults = CATEGORY_DEFAULTS[category].dup

    # 3. Ingredientマスターのunitがある場合はそれを使用
    if ingredient.unit.present?
      defaults[:unit] = ingredient.unit
    end

    defaults
  end

  def estimate_expiry_date(ingredient)
    category = ingredient.category || "others"
    days_to_expire = EXPIRY_DEFAULTS[category]

    Date.current + days_to_expire.days
  end


  def log_conversion_metrics
    metrics = @conversion_metrics

    # 構造化ログで出力
    Rails.logger.info({
      event: "ingredient_conversion_completed",
      user_id: @user&.id,
      fridge_image_id: @fridge_image&.id,
      metrics: {
        total_recognized: metrics[:total_recognized],
        successful_conversions: metrics[:successful_conversions],
        new_ingredients: metrics[:new_ingredients],
        duplicate_updates: metrics[:duplicate_updates],
        skipped_low_confidence: metrics[:skipped_low_confidence],
        unmatched_ingredients: metrics[:unmatched_ingredients],
        errors_count: metrics[:errors].size
      }
    }.to_json)

    # 未マッチ食材の詳細記録
    unmatched = @matcher.unmatched_ingredients
    if unmatched.any?
      Rails.logger.info({
        event: "unmatched_ingredients_recorded",
        fridge_image_id: @fridge_image&.id,
        unmatched_ingredients: unmatched
      }.to_json)
    end
  end

  def conversion_result(success, message, **options)
    result = {
      success: success,
      message: message,
      metrics: @conversion_metrics.dup,
      unmatched_ingredients: @matcher.unmatched_ingredients,
      ambiguous_matches: @matcher.ambiguous_matches
    }.merge(options)

    result
  end
end
