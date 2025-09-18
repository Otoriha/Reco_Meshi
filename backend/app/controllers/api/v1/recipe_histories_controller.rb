class Api::V1::RecipeHistoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_recipe_history, only: [ :show, :update, :destroy ]


  # GET /api/v1/recipe_histories
  # 常にcooked_atの降順（最新順）で返却
  def index
    histories = filtered_histories_scope
                  .includes(:recipe)
                  .recent

    # Kaminari ページネーション（デフォルト20、最大100）
    per = [ [ (params[:per_page] || 20).to_i, 1 ].max, 100 ].min
    histories = histories.page(params[:page]).per(per)

    render json: {
      success: true,
      data: histories.map { |history| recipe_history_json(history) },
      meta: {
        current_page: histories.current_page,
        per_page: histories.limit_value,
        total_pages: histories.total_pages,
        total_count: histories.total_count
      }
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
        message: "調理記録の更新に失敗しました"
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

  # フィルタ条件を適用したRelationを返す
  def filtered_histories_scope
    histories = current_user.recipe_histories

    # 日付フィルタ（start_date/end_date）
    start_date = parse_date_param(params[:start_date])
    end_date = parse_date_param(params[:end_date])
    histories = histories.cooked_after(start_date&.beginning_of_day) if start_date
    histories = histories.cooked_before(end_date&.end_of_day) if end_date

    # レシピIDフィルタ
    histories = histories.where(recipe_id: params[:recipe_id]) if params[:recipe_id].present?

    # 評価済みフィルタ
    if params[:rated_only].present?
      histories = histories.rated if ActiveModel::Type::Boolean.new.cast(params[:rated_only])
    end

    histories
  end

  def recipe_history_params
    params.require(:recipe_history).permit(:recipe_id, :memo, :cooked_at, :rating)
  end

  def update_params
    params.require(:recipe_history).permit(:rating, :memo)
  end

  # 安全な日付パース（不正日付は無視）
  def parse_date_param(date_string)
    return nil if date_string.blank?
    Time.zone.parse(date_string)
  rescue ArgumentError => e
    Rails.logger.warn "Invalid date format: #{date_string} - #{e.message}"
    nil
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
