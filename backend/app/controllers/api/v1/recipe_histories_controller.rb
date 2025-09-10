class Api::V1::RecipeHistoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_recipe_history, only: [ :show, :update, :destroy ]

  # GET /api/v1/recipe_histories
  def index
    histories = filter_recipe_histories
    
    render json: {
      success: true,
      data: histories.map { |history| recipe_history_json(history) },
      meta: pagination_meta(histories)
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

  # DELETE /api/v1/recipe_histories/:id
  def destroy
    @recipe_history.destroy!
    
    render json: {
      success: true,
      message: "レシピ履歴を削除しました"
    }
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: {
      success: false,
      errors: e.record.errors.full_messages,
      message: "レシピ履歴の削除に失敗しました"
    }, status: :unprocessable_entity
  end

  private

  def find_recipe_history
    @recipe_history = current_user.recipe_histories.find(params[:id])
  end

  def filter_recipe_histories
    histories = current_user.recipe_histories.includes(:recipe)

    # 日付フィルタ
    if params[:start_date].present?
      from = Time.zone.parse(params[:start_date]).beginning_of_day rescue nil
      histories = histories.where('cooked_at >= ?', from) if from
    end
    if params[:end_date].present?
      to = Time.zone.parse(params[:end_date]).end_of_day rescue nil
      histories = histories.where('cooked_at <= ?', to) if to
    end

    # レシピIDフィルタ
    histories = histories.where(recipe_id: params[:recipe_id]) if params[:recipe_id].present?
    
    # 評価済みフィルタ
    if params[:rated_only].present?
      histories = histories.rated if ActiveModel::Type::Boolean.new.cast(params[:rated_only])
    end

    # ページネーション（limit/offset方式）
    page = [params[:page].to_i, 1].max
    per_page = [[(params[:per_page] || 20).to_i, 1].max, 100].min
    offset = (page - 1) * per_page

    # 並び替えとページネーション適用
    histories.recent.limit(per_page).offset(offset)
  end

  def pagination_meta(histories)
    # 総数を取得するため再度クエリ実行（limit/offset除く）
    total_count = filter_base_query.count
    page = [params[:page].to_i, 1].max
    per_page = [[(params[:per_page] || 20).to_i, 1].max, 100].min
    total_pages = (total_count.to_f / per_page).ceil

    {
      current_page: page,
      per_page: per_page,
      total_pages: total_pages,
      total_count: total_count
    }
  end

  def filter_base_query
    histories = current_user.recipe_histories

    # 同じフィルタ条件を適用（ページネーション除く）
    if params[:start_date].present?
      from = Time.zone.parse(params[:start_date]).beginning_of_day rescue nil
      histories = histories.where('cooked_at >= ?', from) if from
    end
    if params[:end_date].present?
      to = Time.zone.parse(params[:end_date]).end_of_day rescue nil
      histories = histories.where('cooked_at <= ?', to) if to
    end

    histories = histories.where(recipe_id: params[:recipe_id]) if params[:recipe_id].present?
    
    if params[:rated_only].present?
      histories = histories.rated if ActiveModel::Type::Boolean.new.cast(params[:rated_only])
    end

    histories
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
