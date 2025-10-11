import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  getShoppingLists,
  getShoppingList,
  updateShoppingListItem,
  bulkUpdateShoppingListItems,
  completeShoppingList
} from '../src/api/shoppingLists'
import type {
  ShoppingListsResponse,
  ShoppingListResponse
} from '../src/types/shoppingList'

// APIクライアントのモック
vi.mock('../src/api/client', () => ({
  apiClient: {
    get: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn()
  }
}))

// モック化されたAPIクライアントを取得
const { apiClient } = await import('../src/api/client')
const mockApiClient = vi.mocked(apiClient)

describe('ShoppingLists API', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('getShoppingLists', () => {
    it('買い物リスト一覧を正規化して返す', async () => {
      const mockResponse: ShoppingListsResponse = {
        data: [
          {
            id: '1',
            type: 'shopping_list',
            attributes: {
              title: 'テスト買い物リスト',
              status: 'pending',
              status_display: '未開始',
              display_title: 'テスト買い物リスト',
              completion_percentage: 50,
              total_items_count: 4,
              unchecked_items_count: 2,
              can_be_completed: false,
              created_at: '2023-01-01T00:00:00Z',
              updated_at: '2023-01-01T00:00:00Z'
            }
          }
        ],
        included: []
      }

      mockApiClient.get.mockResolvedValue({ data: mockResponse })

      const result = await getShoppingLists()

      expect(mockApiClient.get).toHaveBeenCalledWith('/shopping_lists', { params: {} })
      expect(result).toHaveLength(1)
      expect(result[0]).toEqual({
        id: 1,
        title: 'テスト買い物リスト',
        status: 'pending',
        statusDisplay: '未開始',
        displayTitle: 'テスト買い物リスト',
        completionPercentage: 50,
        totalItemsCount: 4,
        uncheckedItemsCount: 2,
        canBeCompleted: false,
        createdAt: '2023-01-01T00:00:00Z',
        updatedAt: '2023-01-01T00:00:00Z'
      })
    })

    it('パラメータを適切に渡す', async () => {
      const mockResponse: ShoppingListsResponse = { data: [] }
      mockApiClient.get.mockResolvedValue({ data: mockResponse })

      await getShoppingLists({
        page: 2,
        per_page: 10,
        status: 'pending'
      })

      expect(mockApiClient.get).toHaveBeenCalledWith('/shopping_lists', {
        params: {
          page: 2,
          per_page: 10,
          status: 'pending'
        }
      })
    })
  })

  describe('getShoppingList', () => {
    it('買い物リスト詳細を正規化して返す', async () => {
      const mockResponse: ShoppingListResponse = {
        data: {
          id: '1',
          type: 'shopping_list',
          attributes: {
            title: 'テスト買い物リスト',
            status: 'pending',
            status_display: '未開始',
            display_title: 'テスト買い物リスト',
            completion_percentage: 50,
            total_items_count: 2,
            unchecked_items_count: 1,
            can_be_completed: false,
            created_at: '2023-01-01T00:00:00Z',
            updated_at: '2023-01-01T00:00:00Z'
          },
          relationships: {
            shopping_list_items: {
              data: [
                { type: 'shopping_list_item', id: '1' }
              ]
            }
          }
        },
        included: [
          {
            id: '1',
            type: 'shopping_list_item',
            attributes: {
              quantity: 2,
              unit: '個',
              is_checked: false,
              checked_at: null,
              lock_version: 0,
              display_quantity_with_unit: '2個',
              created_at: '2023-01-01T00:00:00Z',
              updated_at: '2023-01-01T00:00:00Z'
            }
          }
        ]
      }

      mockApiClient.get.mockResolvedValue({ data: mockResponse })

      const result = await getShoppingList(1)

      expect(mockApiClient.get).toHaveBeenCalledWith('/shopping_lists/1')
      expect(result.id).toBe(1)
      expect(result.shoppingListItems).toHaveLength(1)
      expect(result.shoppingListItems![0].id).toBe(1)
      expect(result.shoppingListItems![0].isChecked).toBe(false)
    })
  })

  describe('updateShoppingListItem', () => {
    it('アイテムを更新して正規化した結果を返す', async () => {
      const mockResponse: ShoppingListResponse = {
        data: {
          id: '1',
          type: 'shopping_list_item',
          attributes: {
            quantity: 2,
            unit: '個',
            is_checked: true,
            checked_at: '2023-01-01T01:00:00Z',
            lock_version: 1,
            display_quantity_with_unit: '2個',
            created_at: '2023-01-01T00:00:00Z',
            updated_at: '2023-01-01T01:00:00Z'
          }
        }
      }

      mockApiClient.patch.mockResolvedValue({ data: mockResponse })

      const result = await updateShoppingListItem(1, 1, {
        isChecked: true,
        lockVersion: 0
      })

      expect(mockApiClient.patch).toHaveBeenCalledWith(
        '/shopping_lists/1/items/1',
        {
          shopping_list_item: {
            is_checked: true,
            lock_version: 0
          }
        }
      )
      expect(result.id).toBe(1)
      expect(result.isChecked).toBe(true)
      expect(result.lockVersion).toBe(1)
    })
  })

  describe('bulkUpdateShoppingListItems', () => {
    it('複数アイテムを一括更新する', async () => {
      const mockResponse = {
        data: [
          {
            id: '1',
            type: 'shopping_list_item',
            attributes: {
              quantity: 2,
              unit: '個',
              is_checked: true,
              checked_at: '2023-01-01T01:00:00Z',
              lock_version: 1,
              display_quantity_with_unit: '2個',
              created_at: '2023-01-01T00:00:00Z',
              updated_at: '2023-01-01T01:00:00Z'
            }
          }
        ]
      }

      mockApiClient.patch.mockResolvedValue({ data: mockResponse })

      const result = await bulkUpdateShoppingListItems(1, [
        { id: 1, isChecked: true, lockVersion: 0 }
      ])

      expect(mockApiClient.patch).toHaveBeenCalledWith(
        '/shopping_lists/1/items/bulk_update',
        {
          items: [
            { id: 1, is_checked: true, lock_version: 0 }
          ]
        }
      )
      expect(result).toHaveLength(1)
      expect(result[0].isChecked).toBe(true)
    })

    it('エラーレスポンスの場合は例外を投げる', async () => {
      const mockResponse = {
        errors: [{ detail: 'Update failed' }]
      }

      mockApiClient.patch.mockResolvedValue({ data: mockResponse })

      await expect(
        bulkUpdateShoppingListItems(1, [
          { id: 1, isChecked: true, lockVersion: 0 }
        ])
      ).rejects.toThrow('Update failed')
    })
  })

  describe('completeShoppingList', () => {
    it('買い物リストを完了状態にする', async () => {
      const mockResponse: ShoppingListResponse = {
        data: {
          id: '1',
          type: 'shopping_list',
          attributes: {
            title: 'テスト買い物リスト',
            status: 'completed',
            status_display: '完了',
            display_title: 'テスト買い物リスト',
            completion_percentage: 100,
            total_items_count: 2,
            unchecked_items_count: 0,
            can_be_completed: true,
            created_at: '2023-01-01T00:00:00Z',
            updated_at: '2023-01-01T02:00:00Z'
          }
        }
      }

      mockApiClient.patch.mockResolvedValue({ data: mockResponse })

      const result = await completeShoppingList(1)

      expect(mockApiClient.patch).toHaveBeenCalledWith('/shopping_lists/1/complete')
      expect(result.id).toBe(1)
      expect(result.status).toBe('completed')
      expect(result.completionPercentage).toBe(100)
    })
  })
})