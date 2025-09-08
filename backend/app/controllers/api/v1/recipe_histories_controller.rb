class Api::V1::RecipeHistoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_recipe_history, only: [ :show, :update ]

  # GET /api/v1/recipe_histories
  def index
    recipe_histories = current_user.recipe_histories
                                  .includes(:recipe)
                                  .recent
                                  .limit(100)

    render json: {
      success: true,
      data: recipe_histories.map { |history| recipe_history_json(history) }
    }
  end

  # GET /api/v1/recipe_histories/:id
  def show
    render json: {
      success: true,
      data: recipe_history_json(@recipe_history)
    }
  end

  # POST /api/v1/recipe_histories
  def create
    recipe_history = current_user.recipe_histories.build(recipe_history_params)

    if recipe_history.save
      render json: {
        success: true,
        data: recipe_history_json(recipe_history),
        message: "調理記録を保存しました"
      }, status: :created
    else
      render json: {
        success: false,
        errors: recipe_history.errors.full_messages,
        message: "調理記録の保存に失敗しました"
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/recipe_histories/:id
  def update
    if @recipe_history.update(update_params)
      render json: {
        success: true,
        data: recipe_history_json(@recipe_history),
        message: "評価を更新しました"
      }
    else
      render json: {
        success: false,
        errors: @recipe_history.errors.full_messages,
        message: "評価の更新に失敗しました"
      }, status: :unprocessable_entity
    end
  end

  private

  def find_recipe_history
    @recipe_history = current_user.recipe_histories.find(params[:id])
  end

  def recipe_history_params
    params.require(:recipe_history).permit(:recipe_id, :memo, :cooked_at, :rating)
  end

  def update_params
    params.require(:recipe_history).permit(:rating)
  end

  def recipe_history_json(history)
    {
      id: history.id,
      user_id: history.user_id,
      recipe_id: history.recipe_id,
      cooked_at: history.cooked_at,
      memo: history.memo,
      rating: history.rating,
      created_at: history.created_at,
      updated_at: history.updated_at,
      recipe: history.recipe ? {
        id: history.recipe.id,
        title: history.recipe.title,
        cooking_time: history.recipe.cooking_time,
        difficulty: history.recipe.difficulty
      } : nil
    }
  end
end
