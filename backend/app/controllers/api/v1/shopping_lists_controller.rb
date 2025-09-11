class Api::V1::ShoppingListsController < ApplicationController
  before_action :set_shopping_list, only: [:show, :update, :destroy]
  before_action :authorize_user!, only: [:show, :update, :destroy]

  # GET /api/v1/shopping_lists
  def index
    records = current_user.shopping_lists
                          .includes(:recipe, shopping_list_items: :ingredient)
                          .recent
    
    # Status filtering
    records = records.by_status(params[:status]) if params[:status].present?
    
    # Recipe filtering
    records = records.where(recipe_id: params[:recipe_id]) if params[:recipe_id].present?

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min

    @shopping_lists = records.page(page).per(per_page)
    
    render json: ShoppingListSerializer.new(@shopping_lists, include: [:recipe]).serializable_hash
  end

  # GET /api/v1/shopping_lists/:id
  def show
    render json: ShoppingListSerializer.new(
      @shopping_list, 
      include: [:recipe, :shopping_list_items, 'shopping_list_items.ingredient']
    ).serializable_hash
  end

  # POST /api/v1/shopping_lists
  def create
    if params[:recipe_id].present?
      create_from_recipe
    else
      create_manually
    end
  rescue StandardError => e
    Rails.logger.error "ShoppingList作成エラー: #{e.message}"
    render json: { errors: [{ detail: e.message }] }, status: :unprocessable_entity
  end

  # PATCH/PUT /api/v1/shopping_lists/:id
  def update
    if @shopping_list.update(shopping_list_params)
      render json: ShoppingListSerializer.new(@shopping_list).serializable_hash
    else
      render json: { errors: format_errors(@shopping_list.errors) }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/shopping_lists/:id
  def destroy
    @shopping_list.destroy
    head :no_content
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [{ detail: '買い物リストが見つかりません' }] }, status: :not_found
  end

  def authorize_user!
    unless @shopping_list.user == current_user
      render json: { errors: [{ detail: 'アクセス権限がありません' }] }, status: :forbidden
    end
  end

  def create_from_recipe
    recipe = current_user.recipes.find(params[:recipe_id])
    builder = ShoppingListBuilder.new(current_user, recipe)
    @shopping_list = builder.build

    render json: ShoppingListSerializer.new(
      @shopping_list,
      include: [:recipe, :shopping_list_items, 'shopping_list_items.ingredient']
    ).serializable_hash, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [{ detail: 'レシピが見つかりません' }] }, status: :not_found
  end

  def create_manually
    @shopping_list = current_user.shopping_lists.build(shopping_list_params)
    
    if @shopping_list.save
      render json: ShoppingListSerializer.new(@shopping_list).serializable_hash, status: :created
    else
      render json: { errors: format_errors(@shopping_list.errors) }, status: :unprocessable_entity
    end
  end

  def shopping_list_params
    params.require(:shopping_list).permit(:status, :title, :note, :recipe_id)
  end

  def format_errors(errors)
    errors.full_messages.map { |message| { detail: message } }
  end
end