import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getUserIngredients, updateUserIngredient, deleteUserIngredient } from '../src/api/ingredients'
import { apiClient } from '../src/api/client'

// apiClientをモック
vi.mock('../src/api/client', () => ({
  apiClient: {
    get: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockApiClient = vi.mocked(apiClient)

describe('ingredients API', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('getUserIngredients', () => {
    const mockUserIngredient = {
      id: 1,
      user_id: 1,
      ingredient_id: 1,
      quantity: 2.5,
      status: 'available',
      expiry_date: '2024-08-30',
      created_at: '2024-08-26T00:00:00Z',
      updated_at: '2024-08-26T00:00:00Z',
      ingredient: {
        id: 1,
        name: 'にんじん',
        category: '野菜',
        unit: '本',
        emoji: '🥕',
        display_name_with_emoji: '🥕 にんじん',
        created_at: '2024-08-26T00:00:00Z',
        updated_at: '2024-08-26T00:00:00Z',
      },
      display_name: '🥕 にんじん',
      formatted_quantity: '2.5本',
      days_until_expiry: 4,
      expired: false,
      expiring_soon: true,
    }

    it('通常の一覧取得（group_byなし）', async () => {
      const mockResponse = {
        data: {
          status: { code: 200, message: '在庫を取得しました。' },
          data: [mockUserIngredient],
        },
      }
      mockApiClient.get.mockResolvedValueOnce(mockResponse)

      const result = await getUserIngredients()

      expect(mockApiClient.get).toHaveBeenCalledWith('/user_ingredients', { params: undefined })
      expect(result).toEqual(mockResponse.data)
    })

    it('カテゴリー別グループ取得（group_by=category）', async () => {
      const mockGroupedResponse = {
        data: {
          status: { code: 200, message: '在庫を取得しました。' },
          data: {
            '野菜': [mockUserIngredient],
          },
        },
      }
      mockApiClient.get.mockResolvedValueOnce(mockGroupedResponse)

      const result = await getUserIngredients('category')

      expect(mockApiClient.get).toHaveBeenCalledWith('/user_ingredients', {
        params: { group_by: 'category' },
      })
      expect(result).toEqual(mockGroupedResponse.data)
    })

    it('APIエラー時は例外をスロー', async () => {
      mockApiClient.get.mockRejectedValueOnce(new Error('Network Error'))

      await expect(getUserIngredients()).rejects.toThrow('Network Error')
    })
  })

  describe('updateUserIngredient', () => {
    it('食材数量を正常に更新', async () => {
      const updateData = { quantity: 3.0 }
      const mockResponse = {
        data: {
          status: { code: 200, message: '在庫を更新しました。' },
          data: {
            id: 1,
            quantity: 3.0,
            // その他のフィールド...
          },
        },
      }
      mockApiClient.put.mockResolvedValueOnce(mockResponse)

      const result = await updateUserIngredient(1, updateData)

      expect(mockApiClient.put).toHaveBeenCalledWith('/user_ingredients/1', {
        user_ingredient: updateData,
      })
      expect(result).toEqual(mockResponse.data)
    })

    it('有効期限を更新', async () => {
      const updateData = { expiry_date: '2024-09-01' }
      const mockResponse = {
        data: {
          status: { code: 200, message: '在庫を更新しました。' },
          data: {
            id: 1,
            expiry_date: '2024-09-01',
          },
        },
      }
      mockApiClient.put.mockResolvedValueOnce(mockResponse)

      const result = await updateUserIngredient(1, updateData)

      expect(mockApiClient.put).toHaveBeenCalledWith('/user_ingredients/1', {
        user_ingredient: updateData,
      })
      expect(result).toEqual(mockResponse.data)
    })

    it('有効期限をnullに設定', async () => {
      const updateData = { expiry_date: null }
      const mockResponse = {
        data: {
          status: { code: 200, message: '在庫を更新しました。' },
          data: {
            id: 1,
            expiry_date: null,
          },
        },
      }
      mockApiClient.put.mockResolvedValueOnce(mockResponse)

      const result = await updateUserIngredient(1, updateData)

      expect(mockApiClient.put).toHaveBeenCalledWith('/user_ingredients/1', {
        user_ingredient: updateData,
      })
      expect(result).toEqual(mockResponse.data)
    })

    it('複数項目の同時更新', async () => {
      const updateData = { quantity: 1.5, expiry_date: '2024-08-28' }
      const mockResponse = {
        data: {
          status: { code: 200, message: '在庫を更新しました。' },
          data: {
            id: 1,
            quantity: 1.5,
            expiry_date: '2024-08-28',
          },
        },
      }
      mockApiClient.put.mockResolvedValueOnce(mockResponse)

      const result = await updateUserIngredient(1, updateData)

      expect(mockApiClient.put).toHaveBeenCalledWith('/user_ingredients/1', {
        user_ingredient: updateData,
      })
      expect(result).toEqual(mockResponse.data)
    })

    it('更新API エラー時は例外をスロー', async () => {
      mockApiClient.put.mockRejectedValueOnce(new Error('Update failed'))

      await expect(updateUserIngredient(1, { quantity: 1.0 })).rejects.toThrow('Update failed')
    })
  })

  describe('deleteUserIngredient', () => {
    it('食材を正常に削除（204 No Content）', async () => {
      mockApiClient.delete.mockResolvedValueOnce({ status: 204 })

      await deleteUserIngredient(1)

      expect(mockApiClient.delete).toHaveBeenCalledWith('/user_ingredients/1')
    })

    it('削除API エラー時は例外をスロー', async () => {
      mockApiClient.delete.mockRejectedValueOnce(new Error('Delete failed'))

      await expect(deleteUserIngredient(1)).rejects.toThrow('Delete failed')
    })

    it('存在しないIDの削除も処理', async () => {
      mockApiClient.delete.mockRejectedValueOnce({
        response: { status: 404, data: { error: 'Not Found' } },
      })

      await expect(deleteUserIngredient(999)).rejects.toMatchObject({
        response: { status: 404 },
      })
    })
  })
})