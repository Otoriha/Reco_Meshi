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
end
