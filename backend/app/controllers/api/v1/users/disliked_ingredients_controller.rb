class Api::V1::Users::DislikedIngredientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_disliked_ingredient, only: [ :update, :destroy ]

  # GET /api/v1/users/disliked_ingredients
  def index
    disliked_ingredients = current_user.disliked_ingredients.includes(:ingredient).recent
    serialized_data = DislikedIngredientSerializer.new(disliked_ingredients).serializable_hash
    render json: serialized_data[:data].map { |item| item[:attributes] }
  end

  # POST /api/v1/users/disliked_ingredients
  def create
    disliked_ingredient = current_user.disliked_ingredients.build(disliked_ingredient_params)

    if disliked_ingredient.save
      serialized_data = DislikedIngredientSerializer.new(disliked_ingredient).serializable_hash
      render json: serialized_data[:data][:attributes], status: :created
    else
      render json: { errors: disliked_ingredient.errors.messages }, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    if e.message.include?("is not a valid priority")
      render json: { errors: { priority: [ e.message ] } }, status: :unprocessable_entity
    else
      raise
    end
  end

  # PATCH /api/v1/users/disliked_ingredients/:id
  def update
    if @disliked_ingredient.update(disliked_ingredient_params)
      serialized_data = DislikedIngredientSerializer.new(@disliked_ingredient).serializable_hash
      render json: serialized_data[:data][:attributes]
    else
      render json: { errors: @disliked_ingredient.errors.messages }, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    if e.message.include?("is not a valid priority")
      render json: { errors: { priority: [ e.message ] } }, status: :unprocessable_entity
    else
      raise
    end
  end

  # DELETE /api/v1/users/disliked_ingredients/:id
  def destroy
    @disliked_ingredient.destroy
    head :no_content
  end

  private

  def set_disliked_ingredient
    @disliked_ingredient = current_user.disliked_ingredients.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "苦手食材が見つかりません" }, status: :not_found
  end

  def disliked_ingredient_params
    params.require(:disliked_ingredient).permit(:ingredient_id, :priority, :reason)
  end
end
