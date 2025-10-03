class Api::V1::FavoriteRecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_favorite_recipe, only: [ :update, :destroy ]

  # GET /api/v1/favorite_recipes
  # お気に入りレシピ一覧を取得
  def index
    favorites = current_user.favorite_recipes
                  .includes(:recipe)
                  .recent

    # Kaminari ページネーション（デフォルト20、最大100）
    per = [ [ (params[:per_page] || 20).to_i, 1 ].max, 100 ].min
    favorites = favorites.page(params[:page]).per(per)

    render json: {
      success: true,
      data: favorites.map { |favorite| favorite_recipe_json(favorite) },
      meta: {
        current_page: favorites.current_page,
        per_page: favorites.limit_value,
        total_pages: favorites.total_pages,
        total_count: favorites.total_count
      }
    }
  end

  # POST /api/v1/favorite_recipes
  # お気に入りレシピを追加
  def create
    favorite = current_user.favorite_recipes.build(create_favorite_recipe_params)

    if favorite.save
      render json: {
        success: true,
        data: favorite_recipe_json(favorite),
        message: "お気に入りに追加しました"
      }, status: :created
    else
      render json: {
        success: false,
        errors: favorite.errors.messages.transform_keys { |key| key == :recipe ? :recipe_id : key }.values.flatten,
        message: "お気に入りの追加に失敗しました"
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/favorite_recipes/:id
  # お気に入りレシピの評価を更新
  def update
    if @favorite_recipe.update(update_favorite_recipe_params)
      render json: {
        success: true,
        data: favorite_recipe_json(@favorite_recipe),
        message: "評価を更新しました"
      }
    else
      render json: {
        success: false,
        errors: @favorite_recipe.errors.full_messages,
        message: "評価の更新に失敗しました"
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/favorite_recipes/:id
  # お気に入りレシピを削除
  def destroy
    @favorite_recipe.destroy!

    render json: {
      success: true,
      message: "お気に入りから削除しました"
    }
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: {
      success: false,
      errors: e.record.errors.full_messages,
      message: "お気に入りの削除に失敗しました"
    }, status: :unprocessable_entity
  end

  private

  def find_favorite_recipe
    @favorite_recipe = current_user.favorite_recipes.find(params[:id])
  end

  def create_favorite_recipe_params
    params.require(:favorite_recipe).permit(:recipe_id, :rating)
  end

  def update_favorite_recipe_params
    params.require(:favorite_recipe).permit(:rating)
  end

  def favorite_recipe_json(favorite)
    {
      id: favorite.id,
      user_id: favorite.user_id,
      recipe_id: favorite.recipe_id,
      rating: favorite.rating,
      created_at: favorite.created_at,
      recipe: favorite.recipe ? {
        id: favorite.recipe.id,
        title: favorite.recipe.title,
        cooking_time: favorite.recipe.cooking_time,
        difficulty: favorite.recipe.difficulty,
        servings: favorite.recipe.servings
      } : nil
    }
  end
end
