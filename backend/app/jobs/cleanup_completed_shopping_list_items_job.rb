class CleanupCompletedShoppingListItemsJob < ApplicationJob
  queue_as :default

  # 完了から1日経過したアイテムを自動削除する
  CLEANUP_DAYS = 1

  def perform
    cutoff_date = CLEANUP_DAYS.days.ago

    deleted_count = ShoppingListItem.joins(:shopping_list)
      .where(status: "completed")
      .where("shopping_list_items.updated_at < ?", cutoff_date)
      .delete_all

    Rails.logger.info "Cleaned up #{deleted_count} completed shopping list items older than #{CLEANUP_DAYS} day"

    # 空になった買い物リストも削除する
    empty_lists = ShoppingList.left_joins(:shopping_list_items)
      .group("shopping_lists.id")
      .having("COUNT(shopping_list_items.id) = 0")
      .where("shopping_lists.updated_at < ?", cutoff_date)

    empty_count = empty_lists.delete_all
    Rails.logger.info "Cleaned up #{empty_count} empty shopping lists older than #{CLEANUP_DAYS} day"
  end
end
