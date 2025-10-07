class Api::V1::Users::AllergyIngredientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_allergy_ingredient, only: [ :update, :destroy ]

  # GET /api/v1/users/allergy_ingredients
  def index
    allergy_ingredients = current_user.allergy_ingredients.includes(:ingredient).recent
    serialized_data = AllergyIngredientSerializer.new(allergy_ingredients).serializable_hash
    render json: serialized_data[:data].map { |item| item[:attributes] }
  end

  # POST /api/v1/users/allergy_ingredients
  def create
    allergy_ingredient = current_user.allergy_ingredients.build(allergy_ingredient_params)

    if allergy_ingredient.save
      serialized_data = AllergyIngredientSerializer.new(allergy_ingredient).serializable_hash
      render json: serialized_data[:data][:attributes], status: :created
    else
      render json: { errors: allergy_ingredient.errors.messages }, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    render json: { errors: { severity: [ e.message ] } }, status: :unprocessable_entity
  end

  # PATCH /api/v1/users/allergy_ingredients/:id
  def update
    if @allergy_ingredient.update(allergy_ingredient_params)
      serialized_data = AllergyIngredientSerializer.new(@allergy_ingredient).serializable_hash
      render json: serialized_data[:data][:attributes]
    else
      render json: { errors: @allergy_ingredient.errors.messages }, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    render json: { errors: { severity: [ e.message ] } }, status: :unprocessable_entity
  end

  # DELETE /api/v1/users/allergy_ingredients/:id
  def destroy
    @allergy_ingredient.destroy
    head :no_content
  end

  private

  def set_allergy_ingredient
    @allergy_ingredient = current_user.allergy_ingredients.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "アレルギー食材が見つかりません" }, status: :not_found
  end

  def allergy_ingredient_params
    params.require(:allergy_ingredient).permit(:ingredient_id, :severity, :note)
  end
end
