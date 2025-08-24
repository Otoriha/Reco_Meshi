class Api::V1::UserIngredientsController < ApplicationController
  before_action :set_user_ingredient, only: [:show, :update, :destroy]
  before_action :authorize_user!, only: [:show, :update, :destroy]

  # GET /api/v1/user_ingredients
  # Params: status, category, sort_by, group_by
  def index
    records = current_user.user_ingredients.includes(:ingredient)

    records = records.where(status: params[:status]) if params[:status].present?
    records = records.by_category(params[:category]) if params[:category].present?

    case params[:sort_by]
    when 'expiry_date'
      records = records.order(Arel.sql('CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END ASC')).order(expiry_date: :asc)
    when 'quantity'
      records = records.order(quantity: :desc)
    else
      records = records.recent
    end

    if params[:group_by].to_s == 'category'
      grouped = records.group_by { |ui| ui.ingredient.category }
      data = grouped.transform_values do |items|
        UserIngredientSerializer.new(items).serializable_hash[:data].map { |d| d[:attributes] }
      end
      render json: { status: { code: 200, message: '在庫を取得しました。' }, data: data }, status: :ok
    else
      data = UserIngredientSerializer.new(records).serializable_hash[:data].map { |d| d[:attributes] }
      render json: { status: { code: 200, message: '在庫を取得しました。' }, data: data }, status: :ok
    end
  end

  # GET /api/v1/user_ingredients/:id
  def show
    render json: {
      status: { code: 200, message: '在庫を取得しました。' },
      data: UserIngredientSerializer.new(@user_ingredient).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  # POST /api/v1/user_ingredients
  def create
    attrs = user_ingredient_params.merge(user_id: current_user.id)
    record = UserIngredient.create!(attrs)

    render json: {
      status: { code: 201, message: '在庫を追加しました。' },
      data: UserIngredientSerializer.new(record).serializable_hash[:data][:attributes]
    }, status: :created
  end

  # PUT /api/v1/user_ingredients/:id
  def update
    @user_ingredient.update!(user_ingredient_update_params)
    render json: {
      status: { code: 200, message: '在庫を更新しました。' },
      data: UserIngredientSerializer.new(@user_ingredient).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  # DELETE /api/v1/user_ingredients/:id
  def destroy
    @user_ingredient.destroy
    head :no_content
  end

  private

  def set_user_ingredient
    @user_ingredient = UserIngredient.find(params[:id])
  end

  def authorize_user!
    unless @user_ingredient.user_id == current_user.id
      render json: { error: '権限がありません' }, status: :forbidden
    end
  end

  def user_ingredient_params
    params.require(:user_ingredient).permit(:ingredient_id, :quantity, :expiry_date)
  end

  def user_ingredient_update_params
    params.require(:user_ingredient).permit(:quantity, :expiry_date, :status)
  end
end

