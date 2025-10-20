require 'rails_helper'

RSpec.describe CleanupCompletedShoppingListItemsJob, type: :job do
  let(:user) { create(:user) }

  describe '#perform' do
    context '完了済みアイテムがある場合' do
      it '1日経過した完了済みアイテムを削除する' do
        shopping_list = create(:shopping_list, user: user)

        # 2日前に完了したアイテム（削除対象）
        old_completed_item = create(:shopping_list_item,
          shopping_list: shopping_list,
          is_checked: true,
          checked_at: 2.days.ago,
          updated_at: 2.days.ago
        )

        # 12時間前に完了したアイテム（削除対象外）
        recent_completed_item = create(:shopping_list_item,
          shopping_list: shopping_list,
          is_checked: true,
          checked_at: 12.hours.ago,
          updated_at: 12.hours.ago
        )

        # 未完了のアイテム（削除対象外）
        pending_item = create(:shopping_list_item,
          shopping_list: shopping_list,
          is_checked: false,
          updated_at: 3.days.ago
        )

        expect {
          CleanupCompletedShoppingListItemsJob.perform_now
        }.to change { ShoppingListItem.count }.by(-1)

        expect(ShoppingListItem.exists?(old_completed_item.id)).to be false
        expect(ShoppingListItem.exists?(recent_completed_item.id)).to be true
        expect(ShoppingListItem.exists?(pending_item.id)).to be true
      end
    end

    context '空の買い物リストがある場合' do
      it '1日経過した空の買い物リストを削除する' do
        # 2日前に更新された空の買い物リスト（削除対象）
        old_empty_list = create(:shopping_list, user: user, updated_at: 2.days.ago)

        # 12時間前に更新された空の買い物リスト（削除対象外）
        recent_empty_list = create(:shopping_list, user: user, updated_at: 12.hours.ago)

        # アイテムがある買い物リスト（削除対象外）
        list_with_items = create(:shopping_list, user: user, updated_at: 3.days.ago)
        create(:shopping_list_item, shopping_list: list_with_items)

        expect {
          CleanupCompletedShoppingListItemsJob.perform_now
        }.to change { ShoppingList.count }.by(-1)

        expect(ShoppingList.exists?(old_empty_list.id)).to be false
        expect(ShoppingList.exists?(recent_empty_list.id)).to be true
        expect(ShoppingList.exists?(list_with_items.id)).to be true
      end
    end
  end
end
