import { describe, it, expect, vi, beforeEach } from 'vitest'
import { recipesApi } from '../src/api/recipes'
import { apiClient } from '../src/api/client'

// apiClientをモック
vi.mock('../src/api/client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn()
  }
}))

describe('recipesApi - Extended Methods', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('fetchRecipeHistories', () => {
    it('パラメータなしでデフォルトの履歴を取得する', async () => {
      const mockResponse = {
        data: {
          success: true,
          data: [],
          meta: {
            current_page: 1,
            per_page: 20,
            total_pages: 1,
            total_count: 0
          }
        }
      }

      vi.mocked(apiClient.get).mockResolvedValue(mockResponse)

      const result = await recipesApi.fetchRecipeHistories()

      expect(apiClient.get).toHaveBeenCalledWith('/recipe_histories')
      expect(result.data).toEqual([])
      expect(result.meta).toEqual(mockResponse.data.meta)
    })

    it('フィルタパラメータ付きで履歴を取得する', async () => {
      const mockResponse = {
        data: {
          success: true,
          data: [],
          meta: {
            current_page: 2,
            per_page: 10,
            total_pages: 3,
            total_count: 25
          }
        }
      }

      vi.mocked(apiClient.get).mockResolvedValue(mockResponse)

      const params = {
        page: 2,
        per_page: 10,
        start_date: '2025-09-01',
        end_date: '2025-09-30',
        recipe_id: 1,
        rated_only: true
      }

      await recipesApi.fetchRecipeHistories(params)

      expect(apiClient.get).toHaveBeenCalledWith(
        '/recipe_histories?page=2&per_page=10&start_date=2025-09-01&end_date=2025-09-30&recipe_id=1&rated_only=true'
      )
    })

    it('APIエラー時に例外をスローする', async () => {
      const mockResponse = {
        data: {
          success: false,
          message: 'サーバーエラー'
        }
      }

      vi.mocked(apiClient.get).mockResolvedValue(mockResponse)

      await expect(recipesApi.fetchRecipeHistories()).rejects.toThrow('調理履歴の取得に失敗しました')
    })
  })

  describe('updateRecipeHistory', () => {
    it('評価とメモを更新する', async () => {
      const mockResponse = {
        data: {
          success: true,
          data: {
            id: 1,
            rating: 5,
            memo: '更新されたメモ',
            updated_at: '2025-09-10T12:00:00Z'
          }
        }
      }

      vi.mocked(apiClient.patch).mockResolvedValue(mockResponse)

      const params = { rating: 5, memo: '更新されたメモ' }
      const result = await recipesApi.updateRecipeHistory(1, params)

      expect(apiClient.patch).toHaveBeenCalledWith('/recipe_histories/1', {
        recipe_history: params
      })
      expect(result).toEqual(mockResponse.data.data)
    })

    it('評価のみを更新する', async () => {
      const mockResponse = {
        data: {
          success: true,
          data: {
            id: 1,
            rating: 4,
            updated_at: '2025-09-10T12:00:00Z'
          }
        }
      }

      vi.mocked(apiClient.patch).mockResolvedValue(mockResponse)

      const params = { rating: 4 }
      await recipesApi.updateRecipeHistory(1, params)

      expect(apiClient.patch).toHaveBeenCalledWith('/recipe_histories/1', {
        recipe_history: params
      })
    })

    it('APIエラー時に例外をスローする', async () => {
      const mockResponse = {
        data: {
          success: false,
          message: '更新に失敗しました'
        }
      }

      vi.mocked(apiClient.patch).mockResolvedValue(mockResponse)

      await expect(
        recipesApi.updateRecipeHistory(1, { rating: 5 })
      ).rejects.toThrow('更新に失敗しました')
    })
  })

  describe('deleteRecipeHistory', () => {
    it('履歴を削除する', async () => {
      const mockResponse = {
        data: {
          success: true,
          message: '削除しました'
        }
      }

      vi.mocked(apiClient.delete).mockResolvedValue(mockResponse)

      await recipesApi.deleteRecipeHistory(1)

      expect(apiClient.delete).toHaveBeenCalledWith('/recipe_histories/1')
    })

    it('APIエラー時に例外をスローする', async () => {
      const mockResponse = {
        data: {
          success: false,
          message: '削除に失敗しました'
        }
      }

      vi.mocked(apiClient.delete).mockResolvedValue(mockResponse)

      await expect(recipesApi.deleteRecipeHistory(1)).rejects.toThrow('削除に失敗しました')
    })

    it('エラーメッセージがない場合はデフォルトメッセージを使用する', async () => {
      const mockResponse = {
        data: {
          success: false
        }
      }

      vi.mocked(apiClient.delete).mockResolvedValue(mockResponse)

      await expect(recipesApi.deleteRecipeHistory(1)).rejects.toThrow('調理記録の削除に失敗しました')
    })
  })

  describe('listRecipeHistories (backward compatibility)', () => {
    it('従来のAPIとの互換性を保つ', async () => {
      const mockResponse = {
        data: {
          success: true,
          data: [
            {
              id: 1,
              recipe_id: 1,
              cooked_at: '2025-09-10T12:00:00Z'
            }
          ],
          meta: {
            current_page: 1,
            per_page: 20,
            total_pages: 1,
            total_count: 1
          }
        }
      }

      vi.mocked(apiClient.get).mockResolvedValue(mockResponse)

      const result = await recipesApi.listRecipeHistories()

      expect(result).toEqual(mockResponse.data.data)
    })
  })
})