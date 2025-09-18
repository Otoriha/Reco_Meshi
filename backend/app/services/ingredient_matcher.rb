class IngredientMatcher
  # 設定値
  PARTIAL_MATCH_THRESHOLD = ENV.fetch("INGREDIENT_PARTIAL_MATCH_THRESHOLD", "0.6").to_f
  AMBIGUOUS_SCORE_DIFF = ENV.fetch("INGREDIENT_AMBIGUOUS_SCORE_DIFF", "0.1").to_f
  AUTO_CREATE_ENABLED = ENV.fetch("INGREDIENT_AUTO_CREATE_ENABLED", "false") == "true"

  # ひらがな・カタカナ正規化用のマッピング
  KANA_MAPPING = {
    "あ" => "ア", "い" => "イ", "う" => "ウ", "え" => "エ", "お" => "オ",
    "か" => "カ", "き" => "キ", "く" => "ク", "け" => "ケ", "こ" => "コ",
    "が" => "ガ", "ぎ" => "ギ", "ぐ" => "グ", "げ" => "ゲ", "ご" => "ゴ",
    "さ" => "サ", "し" => "シ", "す" => "ス", "せ" => "セ", "そ" => "ソ",
    "ざ" => "ザ", "じ" => "ジ", "ず" => "ズ", "ぜ" => "ゼ", "ぞ" => "ゾ",
    "た" => "タ", "ち" => "チ", "つ" => "ツ", "て" => "テ", "と" => "ト",
    "だ" => "ダ", "ぢ" => "ヂ", "づ" => "ヅ", "で" => "デ", "ど" => "ド",
    "な" => "ナ", "に" => "ニ", "ぬ" => "ヌ", "ね" => "ネ", "の" => "ノ",
    "は" => "ハ", "ひ" => "ヒ", "ふ" => "フ", "へ" => "ヘ", "ほ" => "ホ",
    "ば" => "バ", "び" => "ビ", "ぶ" => "ブ", "べ" => "ベ", "ぼ" => "ボ",
    "ぱ" => "パ", "ぴ" => "ピ", "ぷ" => "プ", "ぺ" => "ペ", "ぽ" => "ポ",
    "ま" => "マ", "み" => "ミ", "む" => "ム", "め" => "メ", "も" => "モ",
    "や" => "ヤ", "ゆ" => "ユ", "よ" => "ヨ",
    "ら" => "ラ", "り" => "リ", "る" => "ル", "れ" => "レ", "ろ" => "ロ",
    "わ" => "ワ", "ゐ" => "ヰ", "ゑ" => "ヱ", "を" => "ヲ", "ん" => "ン",
    "ゃ" => "ャ", "ゅ" => "ュ", "ょ" => "ョ",
    "っ" => "ッ"
  }.freeze

  # 全角・半角変換マッピング
  ZENKAKU_TO_HANKAKU = {
    "０" => "0", "１" => "1", "２" => "2", "３" => "3", "４" => "4",
    "５" => "5", "６" => "6", "７" => "7", "８" => "8", "９" => "9",
    "Ａ" => "a", "Ｂ" => "b", "Ｃ" => "c", "Ｄ" => "d", "Ｅ" => "e",
    "Ｆ" => "f", "Ｇ" => "g", "Ｈ" => "h", "Ｉ" => "i", "Ｊ" => "j",
    "Ｋ" => "k", "Ｌ" => "l", "Ｍ" => "m", "Ｎ" => "n", "Ｏ" => "o",
    "Ｐ" => "p", "Ｑ" => "q", "Ｒ" => "r", "Ｓ" => "s", "Ｔ" => "t",
    "Ｕ" => "u", "Ｖ" => "v", "Ｗ" => "w", "Ｘ" => "x", "Ｙ" => "y",
    "Ｚ" => "z", "ａ" => "a", "ｂ" => "b", "ｃ" => "c", "ｄ" => "d",
    "ｅ" => "e", "ｆ" => "f", "ｇ" => "g", "ｈ" => "h", "ｉ" => "i",
    "ｊ" => "j", "ｋ" => "k", "ｌ" => "l", "ｍ" => "m", "ｎ" => "n",
    "ｏ" => "o", "ｐ" => "p", "ｑ" => "q", "ｒ" => "r", "ｓ" => "s",
    "ｔ" => "t", "ｕ" => "u", "ｖ" => "v", "ｗ" => "w", "ｘ" => "x",
    "ｙ" => "y", "ｚ" => "z", "　" => " "
  }.freeze

  def initialize
    @unmatched_ingredients = []
    @ambiguous_matches = []
  end

  def find_ingredient(name, auto_create: AUTO_CREATE_ENABLED)
    return nil if name.blank?

    normalized_name = normalize_ingredient_name(name)
    Rails.logger.debug "Normalized ingredient name: '#{name}' -> '#{normalized_name}'"

    # 照合順序の固定: 1.完全一致 → 2.前方一致 → 3.部分一致
    result = find_exact_match(normalized_name) ||
             find_forward_match(normalized_name) ||
             find_partial_match(normalized_name)

    return create_result(result[:ingredient], result[:score]) if result

    # 自動作成が有効な場合
    if auto_create
      created_ingredient = create_unverified_ingredient(name, normalized_name)
      return create_result(created_ingredient, 0.5) if created_ingredient
    end

    # 未マッチの記録
    record_unmatched_ingredient(name, normalized_name)
    nil
  end

  def find_ingredients_batch(names)
    return {} if names.empty?

    candidates = names.map { |name| { original_name: name } }
    ingredient_map = build_ingredient_mapping(candidates)

    # ハッシュ形式で返却：{ original_name => result | nil }
    name_to_result = {}
    names.each do |name|
      if ingredient_map[name]
        ingredient_result = ingredient_map[name]
        name_to_result[name] = create_result(ingredient_result[:ingredient], ingredient_result[:score])
      else
        record_unmatched_ingredient(name, normalize_ingredient_name(name))
        name_to_result[name] = nil
      end
    end

    name_to_result
  end

  def unmatched_ingredients
    @unmatched_ingredients.dup
  end

  def ambiguous_matches
    @ambiguous_matches.dup
  end

  private

  # 統一された名称正規化関数
  def normalize_ingredient_name(name)
    return "" if name.blank?

    normalized = name.to_s.strip

    # 1. 全角・半角変換
    normalized = normalized.chars.map { |char| ZENKAKU_TO_HANKAKU[char] || char }.join

    # 2. ひらがな→カタカナ変換
    normalized = normalized.chars.map { |char| KANA_MAPPING[char] || char }.join

    # 3. 記号・空白除去
    normalized = normalized.gsub(/[[:punct:][:space:]]/, "")

    # 4. 英字小文字化
    normalized.downcase
  end

  def build_ingredient_mapping(candidates)
    return {} if candidates.empty?

    # 正規化された名前を一意にして一括検索
    normalized_names = candidates.map { |c| c[:original_name] }.uniq
    ingredient_map = {}

    # バッチ処理：各正規化された名前に対して個別にDB検索
    normalized_names.each do |original_name|
      normalized_name = normalize_ingredient_name(original_name)
      next if normalized_name.blank?

      # 1回のクエリで候補を取得（find_ingredient の内部ロジックを使用）
      result = find_exact_match(normalized_name) ||
               find_forward_match(normalized_name) ||
               find_partial_match(normalized_name)

      ingredient_map[original_name] = result if result
    end

    ingredient_map
  end

  # SQL側でも正規化を実行する共通メソッド
  def sql_normalize_column(column_name)
    # 1. 全角→半角変換（数字と英字）
    # 2. ひらがな→カタカナ変換
    # 3. 記号・空白除去
    # 4. 小文字化
    "LOWER(REGEXP_REPLACE(TRANSLATE(TRANSLATE(#{column_name}, " \
    "'あいうえおかきくけこがぎぐげごさしすせそざじずぜぞたちつてとだぢづでどなにぬねのはひふへほばびぶべぼぱぴぷぺぽまみむめもやゆよらりるれろわゐゑをんゃゅょっ', " \
    "'アイウエオカキクケコガギグゲゴサシスセソザジズゼゾタチツテトダヂヅデドナニヌネノハヒフヘホバビブベボパピプペポマミムメモヤユヨラリルレロワヰヱヲンャュョッ'), " \
    "'０１２３４５６７８９ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ　', " \
    "'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz '), " \
    "'[[:punct:][:space:]]', '', 'g'))"
  end

  def find_exact_match(normalized_name)
    ingredient = Ingredient.find_by("#{sql_normalize_column('name')} = ?", normalized_name)
    ingredient ? { ingredient: ingredient, score: 1.0 } : nil
  end

  def find_forward_match(normalized_name)
    ingredients = Ingredient.where("#{sql_normalize_column('name')} LIKE ?", "#{normalized_name}%").limit(10)

    return nil if ingredients.empty?

    # 複数候補時の安全性：スコア差をチェック
    if ingredients.count > 1
      scores = ingredients.map { |ing| calculate_similarity_score(normalized_name, normalize_ingredient_name(ing.name)) }
      max_score = scores.max
      second_score = scores.sort.reverse[1] || 0

      # スコア差が小さい場合は保留（曖昧すぎて危険）
      if (max_score - second_score) < AMBIGUOUS_SCORE_DIFF
        record_ambiguous_match(normalized_name, ingredients.to_a)
        return nil # 保留してコンバータ側でスキップ
      end

      record_ambiguous_match(normalized_name, ingredients.to_a)
    end

    { ingredient: ingredients.first, score: 0.8 }
  end

  def find_partial_match(normalized_name)
    return nil if normalized_name.length < 2 # 短すぎる場合はスキップ

    ingredients = Ingredient.where("#{sql_normalize_column('name')} LIKE ?", "%#{normalized_name}%")
                           .where.not("#{sql_normalize_column('name')} LIKE ?", "#{normalized_name}%")
                           .limit(10)

    return nil if ingredients.empty?

    score = ingredients.first ? calculate_similarity_score(normalized_name, normalize_ingredient_name(ingredients.first.name)) : 0.6
    return nil if score < PARTIAL_MATCH_THRESHOLD

    # 複数候補時の安全性チェック
    if ingredients.count > 1
      scores = ingredients.map { |ing| calculate_similarity_score(normalized_name, normalize_ingredient_name(ing.name)) }
      max_score = scores.max
      second_score = scores.sort.reverse[1] || 0

      if (max_score - second_score) < AMBIGUOUS_SCORE_DIFF
        record_ambiguous_match(normalized_name, ingredients.to_a)
        return nil # 保留
      end

      record_ambiguous_match(normalized_name, ingredients.to_a)
    end

    { ingredient: ingredients.first, score: score }
  end

  def calculate_similarity_score(name1, name2)
    # 簡易的な類似度計算（レーベンシュタイン距離の簡易版）
    return 1.0 if name1 == name2

    longer = name1.length > name2.length ? name1 : name2
    shorter = name1.length > name2.length ? name2 : name1

    return 0.0 if longer.empty?

    (longer.length - levenshtein_distance(longer, shorter)).to_f / longer.length
  end

  def levenshtein_distance(str1, str2)
    matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1, 0) }

    (0..str1.length).each { |i| matrix[i][0] = i }
    (0..str2.length).each { |j| matrix[0][j] = j }

    (1..str1.length).each do |i|
      (1..str2.length).each do |j|
        cost = str1[i - 1] == str2[j - 1] ? 0 : 1
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].min
      end
    end

    matrix[str1.length][str2.length]
  end

  def determine_match_score(original_name, normalized_name, ingredient)
    ingredient_normalized = normalize_ingredient_name(ingredient.name)

    return 1.0 if ingredient_normalized == normalized_name
    return 0.8 if ingredient_normalized.start_with?(normalized_name)

    calculate_similarity_score(normalized_name, ingredient_normalized)
  end

  def create_unverified_ingredient(original_name, normalized_name)
    return nil unless AUTO_CREATE_ENABLED

    # 一意制約違反時のリトライ
    3.times do
      begin
        ingredient = Ingredient.create!(
          name: original_name,
          category: "others",
          unit: "個"
          # verified/created_fromカラムは存在しないため削除
        )

        Rails.logger.info "Auto-created ingredient: #{original_name}"
        return ingredient

      rescue ActiveRecord::RecordNotUnique
        # 同時実行で作成された可能性があるため、再取得を試行
        ingredient = Ingredient.find_by(name: original_name)
        return ingredient if ingredient

        sleep(0.1) # 短いリトライ間隔
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn "Failed to auto-create ingredient '#{original_name}': #{e.message}"
        break
      end
    end

    nil
  end

  def create_result(ingredient, confidence)
    {
      ingredient: ingredient,
      confidence: confidence,
      matched: true
    }
  end

  def record_unmatched_ingredient(original_name, normalized_name)
    @unmatched_ingredients << {
      original_name: original_name,
      normalized_name: normalized_name,
      timestamp: Time.current
    }

    Rails.logger.info "Unmatched ingredient recorded: '#{original_name}' (normalized: '#{normalized_name}')"
  end

  def record_ambiguous_match(normalized_name, candidates)
    @ambiguous_matches << {
      normalized_name: normalized_name,
      candidates: candidates.map(&:name),
      timestamp: Time.current
    }

    Rails.logger.debug "Ambiguous match detected for '#{normalized_name}': #{candidates.map(&:name).join(', ')}"
  end
end
