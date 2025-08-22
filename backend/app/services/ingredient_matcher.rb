class IngredientMatcher
  # ひらがな・カタカナ正規化用のマッピング
  KANA_MAPPING = {
    'あ' => 'ア', 'い' => 'イ', 'う' => 'ウ', 'え' => 'エ', 'お' => 'オ',
    'か' => 'カ', 'き' => 'キ', 'く' => 'ク', 'け' => 'ケ', 'こ' => 'コ',
    'が' => 'ガ', 'ぎ' => 'ギ', 'ぐ' => 'グ', 'げ' => 'ゲ', 'ご' => 'ゴ',
    'さ' => 'サ', 'し' => 'シ', 'す' => 'ス', 'せ' => 'セ', 'そ' => 'ソ',
    'ざ' => 'ザ', 'じ' => 'ジ', 'ず' => 'ズ', 'ぜ' => 'ゼ', 'ぞ' => 'ゾ',
    'た' => 'タ', 'ち' => 'チ', 'つ' => 'ツ', 'て' => 'テ', 'と' => 'ト',
    'だ' => 'ダ', 'ぢ' => 'ヂ', 'づ' => 'ヅ', 'で' => 'デ', 'ど' => 'ド',
    'な' => 'ナ', 'に' => 'ニ', 'ぬ' => 'ヌ', 'ね' => 'ネ', 'の' => 'ノ',
    'は' => 'ハ', 'ひ' => 'ヒ', 'ふ' => 'フ', 'へ' => 'ヘ', 'ほ' => 'ホ',
    'ば' => 'バ', 'び' => 'ビ', 'ぶ' => 'ブ', 'べ' => 'ベ', 'ぼ' => 'ボ',
    'ぱ' => 'パ', 'ぴ' => 'ピ', 'ぷ' => 'プ', 'ぺ' => 'ペ', 'ぽ' => 'ポ',
    'ま' => 'マ', 'み' => 'ミ', 'む' => 'ム', 'め' => 'メ', 'も' => 'モ',
    'や' => 'ヤ', 'ゆ' => 'ユ', 'よ' => 'ヨ',
    'ら' => 'ラ', 'り' => 'リ', 'る' => 'ル', 'れ' => 'レ', 'ろ' => 'ロ',
    'わ' => 'ワ', 'ゐ' => 'ヰ', 'ゑ' => 'ヱ', 'を' => 'ヲ', 'ん' => 'ン',
    'ゃ' => 'ャ', 'ゅ' => 'ュ', 'ょ' => 'ョ',
    'っ' => 'ッ'
  }.freeze

  def initialize
    @unmatched_ingredients = []
  end

  def find_ingredient(name)
    return nil if name.blank?

    normalized_name = normalize_name(name)
    
    # 1. 完全一致検索
    exact_match = find_exact_match(normalized_name)
    return create_result(exact_match, 1.0) if exact_match

    # 2. ひらがな・カタカナ正規化検索
    katakana_name = hiragana_to_katakana(normalized_name)
    normalized_match = find_normalized_match(katakana_name)
    return create_result(normalized_match, 0.9) if normalized_match

    # 3. 部分一致検索
    partial_match = find_partial_match(normalized_name)
    return create_result(partial_match[:ingredient], partial_match[:score]) if partial_match

    # 未マッチの記録
    record_unmatched_ingredient(name)
    nil
  end

  def find_ingredients_batch(names)
    names.map { |name| find_ingredient(name) }.compact
  end

  def unmatched_ingredients
    @unmatched_ingredients.dup
  end

  private

  def normalize_name(name)
    name.to_s.strip.downcase.gsub(/\s+/, '')
  end

  def hiragana_to_katakana(name)
    name.chars.map { |char| KANA_MAPPING[char] || char }.join
  end

  def find_exact_match(name)
    Ingredient.find_by('LOWER(name) = ?', name)
  end

  def find_normalized_match(katakana_name)
    # カタカナ正規化後の検索
    Ingredient.where(
      'TRANSLATE(UPPER(name), \'あいうえおかきくけこがぎぐげごさしすせそざじずぜぞたちつてとだぢづでどなにぬねのはひふへほばびぶべぼぱぴぷぺぽまみむめもやゆよらりるれろわゐゑをんゃゅょっ\', 
                             \'アイウエオカキクケコガギグゲゴサシスセソザジズゼゾタチツテトダヂヅデドナニヌネノハヒフヘホバビブベボパピプペポマミムメモヤユヨラリルレロワヰヱヲンャュョッ\') = ?',
      katakana_name
    ).first
  end

  def find_partial_match(name)
    # 部分一致検索（前方一致、後方一致、中間一致）
    candidates = []

    # 前方一致（高い信頼度）
    forward_matches = Ingredient.where('LOWER(name) LIKE ?', "#{name}%")
    candidates.concat(forward_matches.map { |ing| { ingredient: ing, score: 0.8 } })

    # 後方一致（中程度の信頼度）
    backward_matches = Ingredient.where('LOWER(name) LIKE ?', "%#{name}")
    candidates.concat(backward_matches.map { |ing| { ingredient: ing, score: 0.7 } })

    # 中間一致（低い信頼度）
    middle_matches = Ingredient.where('LOWER(name) LIKE ?', "%#{name}%")
                              .where.not(id: (forward_matches + backward_matches).map(&:id))
    candidates.concat(middle_matches.map { |ing| { ingredient: ing, score: 0.6 } })

    # 最高スコアの候補を返す
    candidates.max_by { |candidate| candidate[:score] }
  end

  def create_result(ingredient, confidence)
    {
      ingredient: ingredient,
      confidence: confidence,
      matched: true
    }
  end

  def record_unmatched_ingredient(name)
    @unmatched_ingredients << {
      name: name,
      timestamp: Time.current,
      normalized_name: normalize_name(name)
    }
    
    Rails.logger.info "Unmatched ingredient recorded: #{name}"
  end
end