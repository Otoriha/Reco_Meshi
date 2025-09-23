class Api::V1::RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [ :show ]

  # GET /api/v1/recipes
  def index
    recipes = current_user.recipes.includes(:user).recent.limit(50)
    render json: {
      success: true,
      data: recipes.map { |recipe| recipe_list_json(recipe) }
    }
  end

  # GET /api/v1/recipes/:id
  def show
    render json: {
      success: true,
      data: recipe_detail_json(@recipe)
    }
  end

  # POST /api/v1/recipes/suggest
  def suggest
    begin
      raw_suggestion_params = params[:recipe_suggestion]

      if raw_suggestion_params.present? && raw_suggestion_params.respond_to?(:key?) && raw_suggestion_params.key?(:ingredients)
        raw_ingredients = raw_suggestion_params[:ingredients]

        if raw_ingredients.present? && !raw_ingredients.is_a?(Array)
          return render json: {
            success: false,
            message: "食材は配列で指定してください",
            errors: [ "ingredients must be an array" ]
          }, status: 422
        end
      end

      # パラメータの取得と検証
      suggestion_params = params
        .permit(
          recipe_suggestion: [
            { ingredients: [] },
            { preferences: [
              :cooking_time,
              :difficulty_level,
              :cuisine_type,
              { dietary_restrictions: [] }
            ] }
          ]
        )
        .fetch(:recipe_suggestion, {})

      ingredients = suggestion_params[:ingredients]
      preferences = normalize_preferences((suggestion_params[:preferences] || {}).to_h)


      # RecipeGeneratorを使用してレシピを生成
      generator = RecipeGenerator.new(user: current_user)

      recipe = if ingredients.present?
                 # 指定された食材からレシピ生成
                 generator.generate_from_ingredients(ingredients, preferences)
      else
                 # ユーザーの在庫食材からレシピ生成
                 generator.generate_from_user_ingredients(preferences)
      end

      Rails.logger.info "Recipe suggested successfully: #{recipe.title} (ID: #{recipe.id}) for user #{current_user.id}"

      render json: {
        success: true,
        data: recipe_detail_json(recipe)
      }

    rescue RecipeGenerator::GenerationError => e
      Rails.logger.warn "Recipe generation error for user #{current_user.id}: #{e.message}"
      render json: {
        success: false,
        message: "レシピ生成に失敗しました",
        errors: [ e.message ]
      }, status: 422

    rescue => e
      Rails.logger.error "Unexpected error in recipe suggestion for user #{current_user.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        success: false,
        message: "内部エラーが発生しました。しばらくしてから再度お試しください。"
      }, status: 500
    end
  end

  private

  def set_recipe
    @recipe = current_user.recipes.includes(recipe_ingredients: :ingredient).find(params[:id])
  end

  def recipe_list_json(recipe)
    {
      id: recipe.id,
      title: recipe.title,
      cooking_time: recipe.cooking_time,
      formatted_cooking_time: recipe.formatted_cooking_time,
      difficulty: recipe.difficulty,
      difficulty_display: recipe.difficulty_display,
      servings: recipe.servings,
      created_at: recipe.created_at
    }
  end

  def recipe_detail_json(recipe)
    recipe_list_json(recipe).merge(
      steps: recipe.steps_as_array,
      ingredients: recipe.recipe_ingredients.map do |ri|
        {
          id: ri.id,
          name: ri.ingredient&.name || ri.ingredient_name,
          amount: ri.amount,
          unit: ri.unit,
          is_optional: ri.is_optional
        }
      end
    )
  end

  def normalize_preferences(pref)
    # フロントエンドのキー名をRecipeGeneratorの期待する形式に変換
    normalized = pref.stringify_keys

    # difficulty_level → difficulty にマッピング
    if normalized.key?("difficulty_level")
      normalized["difficulty"] = normalized.delete("difficulty_level")
    end

    # テスト期待に合わせ、値を文字列化（配列も各要素を文字列化）
    normalized.transform_values do |v|
      if v.is_a?(Array)
        v.map { |e| e.to_s }
      else
        v.to_s
      end
    end
  end
end
