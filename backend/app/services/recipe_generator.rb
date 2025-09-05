class RecipeGenerator
  class GenerationError < StandardError; end

  def initialize(user:, llm_provider: 'openai')
    @user = user
    @llm_provider = llm_provider.to_s
    @recipe_converter = RecipeConverter.new
  end

  # ユーザーの利用可能食材からレシピを生成
  def generate_from_user_ingredients(options = {})
    available_ingredients = fetch_user_available_ingredients
    
    if available_ingredients.empty?
      raise GenerationError, '利用可能な食材が見つかりません'
    end

    ingredient_names = available_ingredients.map(&:display_name)
    generate_recipe(ingredient_names, options)
  end

  # 指定された食材リストからレシピを生成
  def generate_from_ingredients(ingredient_names, options = {})
    if ingredient_names.blank? || !ingredient_names.is_a?(Array)
      raise GenerationError, '食材リストが必要です'
    end

    generate_recipe(ingredient_names, options)
  end

  # 生成結果の取得
  def conversion_warnings
    @recipe_converter.conversion_warnings
  end

  def unmatched_ingredients
    @recipe_converter.unmatched_ingredients  
  end

  def ambiguous_matches
    @recipe_converter.ambiguous_matches
  end

  private

  def fetch_user_available_ingredients
    @user.user_ingredients
         .available
         .joins(:ingredient)
         .includes(:ingredient)
         .limit(20) # 最大20個の食材まで
  end

  def generate_recipe(ingredient_names, options = {})
    # 入力検証
    validate_options(options)

    begin
      # LLMサービスを取得
      llm_service = Llm::Factory.build(provider: @llm_provider)
      
      # プロンプトを構築
      prompt = build_recipe_prompt(ingredient_names, options)
      
      # LLMでレシピ生成
      response = llm_service.generate(
        messages: prompt,
        response_format: :json,
        temperature: 0.7,
        max_tokens: 1500
      )
      
      unless response&.text.present?
        raise GenerationError, 'LLMからのレスポンスが空です'
      end

      # JSON形式の確認とパース（raw_jsonを優先）
      begin
        recipe_json = response.raw_json || JSON.parse(response.text)
      rescue JSON::ParserError => e
        Rails.logger.error "Invalid JSON from LLM: #{response.text}"
        raise GenerationError, "LLMからの不正なJSONレスポンス: #{e.message}"
      end

      # RecipeConverterでモデルに変換
      recipe = @recipe_converter.convert(
        user: @user,
        ai_response: recipe_json,
        ai_provider: @llm_provider
      )

      Rails.logger.info "Recipe generated successfully: #{recipe.title} (ID: #{recipe.id})"
      recipe

    rescue RecipeConverter::ConversionError => e
      Rails.logger.error "Recipe conversion error: #{e.message}"
      raise GenerationError, "レシピ変換でエラーが発生しました: #{e.message}"
    rescue => e
      Rails.logger.error "Unexpected error in recipe generation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise GenerationError, "レシピ生成中に予期しないエラーが発生しました"
    end
  end

  def build_recipe_prompt(ingredient_names, options)
    # 基本的なプロンプトを取得
    base_prompt = PromptTemplateService.recipe_generation(ingredients: ingredient_names)
    
    # オプションに応じてプロンプトをカスタマイズ
    customized_system = customize_system_prompt(base_prompt[:system], options)
    customized_user = customize_user_prompt(base_prompt[:user], options)
    
    {
      system: customized_system,
      user: customized_user
    }
  end

  def customize_system_prompt(base_system, options)
    customizations = []
    
    if options[:difficulty]
      difficulty_text = case options[:difficulty].to_s
                       when 'easy'
                         '簡単で初心者でも作れるレシピ'
                       when 'medium'
                         '中程度の難易度のレシピ'
                       when 'hard'
                         '上級者向けの手の込んだレシピ'
                       end
      customizations << difficulty_text if difficulty_text
    end

    if options[:cooking_time]
      time_limit = options[:cooking_time].to_i
      customizations << "調理時間は#{time_limit}分以内"
    end

    if options[:servings]
      servings = options[:servings].to_i
      customizations << "#{servings}人分のレシピ"
    end

    if customizations.any?
      "#{base_system} 追加条件：#{customizations.join('、')}。"
    else
      base_system
    end
  end

  def customize_user_prompt(base_user, options)
    additional_requirements = []
    
    if options[:cuisine_type]
      additional_requirements << "料理の種類：#{options[:cuisine_type]}"
    end

    if options[:dietary_restrictions]
      restrictions = Array(options[:dietary_restrictions]).join('、')
      additional_requirements << "食事制限：#{restrictions}"
    end

    if options[:cooking_method]
      additional_requirements << "調理方法：#{options[:cooking_method]}"
    end

    if additional_requirements.any?
      "#{base_user}\n\n追加要件：#{additional_requirements.join('、')}"
    else
      base_user
    end
  end

  # バリデーション用のヘルパーメソッド
  def validate_options(options)
    if options[:difficulty] && !%w[easy medium hard].include?(options[:difficulty].to_s)
      raise GenerationError, "不正な難易度: #{options[:difficulty]}"
    end

    if options[:cooking_time] && (options[:cooking_time].to_i < 5 || options[:cooking_time].to_i > 480)
      raise GenerationError, "調理時間は5分〜480分の範囲で指定してください"
    end

    if options[:servings] && (options[:servings].to_i < 1 || options[:servings].to_i > 20)
      raise GenerationError, "サービング数は1〜20の範囲で指定してください"  
    end
  end
end