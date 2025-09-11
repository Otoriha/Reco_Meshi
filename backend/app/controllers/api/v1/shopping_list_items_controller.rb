class Api::V1::ShoppingListItemsController < ApplicationController
  before_action :set_shopping_list
  before_action :set_shopping_list_item, only: [:update, :destroy]
  before_action :authorize_user!

  # PATCH/PUT /api/v1/shopping_lists/:shopping_list_id/items/:id
  def update
    if @shopping_list_item.update(shopping_list_item_params)
      render json: ShoppingListItemSerializer.new(@shopping_list_item, include: [:ingredient]).serializable_hash
    else
      render json: { errors: format_errors(@shopping_list_item.errors) }, status: :unprocessable_entity
    end
  rescue ActiveRecord::StaleObjectError
    render json: { 
      errors: [{ 
        detail: '他のユーザーによって更新されています。画面を再読み込みして最新の状態を確認してください。' 
      }] 
    }, status: :conflict
  end

  # DELETE /api/v1/shopping_lists/:shopping_list_id/items/:id
  def destroy
    @shopping_list_item.destroy
    head :no_content
  end

  # PATCH /api/v1/shopping_lists/:shopping_list_id/items/bulk_update
  def bulk_update
    items_params = params.require(:items)
    results = []
    errors = []

    ActiveRecord::Base.transaction do
      items_params.each do |item_params|
        item = @shopping_list.shopping_list_items.find(item_params[:id])
        
        if item.update(item_params.permit(:is_checked, :lock_version))
          results << ShoppingListItemSerializer.new(item, include: [:ingredient]).serializable_hash
        else
          errors << {
            id: item_params[:id],
            errors: format_errors(item.errors)
          }
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { 
        errors: [{ detail: '一部のアイテムの更新に失敗しました' }],
        item_errors: errors
      }, status: :unprocessable_entity
    else
      render json: { data: results }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: [{ detail: 'アイテムが見つかりません' }] }, status: :not_found
  rescue ActiveRecord::StaleObjectError
    render json: { 
      errors: [{ 
        detail: '他のユーザーによって更新されています。画面を再読み込みして最新の状態を確認してください。' 
      }] 
    }, status: :conflict
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:shopping_list_id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [{ detail: '買い物リストが見つかりません' }] }, status: :not_found
  end

  def set_shopping_list_item
    @shopping_list_item = @shopping_list.shopping_list_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [{ detail: 'アイテムが見つかりません' }] }, status: :not_found
  end

  def authorize_user!
    unless @shopping_list&.user == current_user
      render json: { errors: [{ detail: 'アクセス権限がありません' }] }, status: :forbidden
    end
  end

  def shopping_list_item_params
    params.require(:shopping_list_item).permit(:quantity, :unit, :is_checked, :lock_version)
  end

  def format_errors(errors)
    errors.full_messages.map { |message| { detail: message } }
  end
end