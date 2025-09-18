class Api::V1::IngredientsController < ApplicationController
  before_action :set_ingredient, only: [ :update, :destroy ]

  # GET /api/v1/ingredients
  # Params: category, search, page, per_page
  def index
    ingredients = Ingredient.all
    ingredients = ingredients.by_category(params[:category]) if params[:category].present?
    ingredients = ingredients.search(params[:search]) if params[:search].present?

    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20
    per_page = [ per_page, 100 ].min
    total = ingredients.count
    items = ingredients.offset((page - 1) * per_page).limit(per_page)

    data = IngredientSerializer.new(items).serializable_hash[:data].map { |d| d[:attributes] }

    render json: {
      status: { code: 200, message: "食材を取得しました。" },
      data: data,
      meta: { total: total, page: page, per_page: per_page }
    }, status: :ok
  end

  # POST /api/v1/ingredients
  def create
    ingredient = Ingredient.create!(ingredient_params)

    render json: {
      status: { code: 201, message: "食材を作成しました。" },
      data: IngredientSerializer.new(ingredient).serializable_hash[:data][:attributes]
    }, status: :created
  end

  # PUT /api/v1/ingredients/:id
  def update
    @ingredient.update!(ingredient_params)

    render json: {
      status: { code: 200, message: "食材を更新しました。" },
      data: IngredientSerializer.new(@ingredient).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  # DELETE /api/v1/ingredients/:id
  def destroy
    @ingredient.destroy
    head :no_content
  end

  private

  def set_ingredient
    @ingredient = Ingredient.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name, :category, :unit, :emoji)
  end
end
