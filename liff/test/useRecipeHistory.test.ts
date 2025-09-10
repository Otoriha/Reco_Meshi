import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, act, waitFor } from '@testing-library/react'
import { useRecipeHistory } from '../src/hooks/useRecipeHistory'
import { recipesApi } from '../src/api/recipes'

// recipesApiをモック
vi.mock('../src/api/recipes', () => ({
  recipesApi: {
    fetchRecipeHistories: vi.fn(),
    updateRecipeHistory: vi.fn(),
    deleteRecipeHistory: vi.fn()
  }
}))

const mockRecipeHistories = [
  {
    id: 1,
    user_id: 1,
    recipe_id: 1,
    cooked_at: '2025-09-10T12:00:00Z',
    memo: 'テストメモ1',
    rating: 4,
    created_at: '2025-09-10T12:00:00Z',
    updated_at: '2025-09-10T12:00:00Z',
    recipe: {
      id: 1,
      title: 'テストレシピ1',
      cooking_time: 30,
      difficulty: 'easy'
    }
  }
]

const mockMeta = {
  current_page: 1,
  per_page: 20,
  total_pages: 2,
  total_count: 25
}

const mockApiResponse = {
  data: mockRecipeHistories,
  meta: mockMeta
}

describe('useRecipeHistory', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // fetchRecipeHistoriesのデフォルトモック
    vi.mocked(recipesApi.fetchRecipeHistories).mockResolvedValue(mockApiResponse)
  })

  it('初期状態が正しく設定される', () => {
    const { result } = renderHook(() => useRecipeHistory())
    
    expect(result.current.histories).toEqual([])
    expect(result.current.meta).toBe(null)
    expect(result.current.initialized).toBe(false)
    expect(result.current.hasNextPage).toBe(false)
    // 初期化時にデータ取得が開始されるためloadingはtrueになる
  })

  it('初期化時にデータを取得する', async () => {
    const { result } = renderHook(() => useRecipeHistory())
    
    await waitFor(() => {
      expect(result.current.initialized).toBe(true)
    })
    
    expect(recipesApi.fetchRecipeHistories).toHaveBeenCalledWith({ per_page: 20, page: 1 })
    expect(result.current.histories).toEqual(mockRecipeHistories)
    expect(result.current.meta).toEqual(mockMeta)
    expect(result.current.hasNextPage).toBe(true)
  })

  it('fetchHistoriesでパラメータ付きデータを取得する', async () => {
    const { result } = renderHook(() => useRecipeHistory())
    
    await act(async () => {
      await result.current.fetchHistories({ page: 2, rated_only: true }, true)
    })
    
    expect(recipesApi.fetchRecipeHistories).toHaveBeenCalledWith({ 
      per_page: 20, 
      page: 2, 
      rated_only: true 
    })
  })

  it('loadMoreで次のページを読み込む', async () => {
    const { result } = renderHook(() => useRecipeHistory())
    
    // 初期化を待つ
    await waitFor(() => {
      expect(result.current.initialized).toBe(true)
    })
    
    // 次のページの追加データ
    const additionalData = [
      {
        id: 2,
        user_id: 1,
        recipe_id: 2,
        cooked_at: '2025-09-09T12:00:00Z',
        memo: 'テストメモ2',
        rating: 5,
        created_at: '2025-09-09T12:00:00Z',
        updated_at: '2025-09-09T12:00:00Z'
      }
    ]
    
    vi.mocked(recipesApi.fetchRecipeHistories).mockResolvedValueOnce({
      data: additionalData,
      meta: { ...mockMeta, current_page: 2 }
    })
    
    await act(async () => {
      await result.current.loadMore()
    })
    
    expect(recipesApi.fetchRecipeHistories).toHaveBeenCalledWith({ page: 2, per_page: 20 })
    expect(result.current.histories).toHaveLength(2) // 既存 + 新規
  })

  it('updateHistoryで履歴を更新する', async () => {
    const updatedHistory = { ...mockRecipeHistories[0], rating: 5 }
    vi.mocked(recipesApi.updateRecipeHistory).mockResolvedValue(updatedHistory)
    
    const { result } = renderHook(() => useRecipeHistory())
    
    // 初期化を待つ
    await waitFor(() => {
      expect(result.current.initialized).toBe(true)
    })
    
    await act(async () => {
      await result.current.updateHistory(1, { rating: 5 })
    })
    
    expect(recipesApi.updateRecipeHistory).toHaveBeenCalledWith(1, { rating: 5 })
    expect(result.current.histories[0].rating).toBe(5)
  })

  it('deleteHistoryで履歴を削除する', async () => {
    vi.mocked(recipesApi.deleteRecipeHistory).mockResolvedValue(undefined)
    
    const { result } = renderHook(() => useRecipeHistory())
    
    // 初期化を待つ
    await waitFor(() => {
      expect(result.current.initialized).toBe(true)
    })
    
    await act(async () => {
      await result.current.deleteHistory(1)
    })
    
    expect(recipesApi.deleteRecipeHistory).toHaveBeenCalledWith(1)
    expect(result.current.histories).toHaveLength(0)
    expect(result.current.meta?.total_count).toBe(24) // 1減少
  })

  it('API エラー時にエラーメッセージが設定される', async () => {
    const errorMessage = 'API エラー'
    vi.mocked(recipesApi.fetchRecipeHistories).mockRejectedValue(new Error(errorMessage))
    
    const { result } = renderHook(() => useRecipeHistory())
    
    await waitFor(() => {
      expect(result.current.error).toBe(errorMessage)
    })
    
    expect(result.current.loading).toBe(false)
    expect(result.current.initialized).toBe(true)
  })

  it('hasNextPageが正しく計算される', async () => {
    // 最後のページのメタ情報
    const lastPageMeta = {
      current_page: 2,
      per_page: 20,
      total_pages: 2,
      total_count: 25
    }
    
    vi.mocked(recipesApi.fetchRecipeHistories).mockResolvedValue({
      data: [],
      meta: lastPageMeta
    })
    
    const { result } = renderHook(() => useRecipeHistory())
    
    await waitFor(() => {
      expect(result.current.initialized).toBe(true)
    })
    
    expect(result.current.hasNextPage).toBe(false)
  })

  it('refreshHistoriesでデータを再取得する', async () => {
    const { result } = renderHook(() => useRecipeHistory())
    
    // 初期化を待つ
    await waitFor(() => {
      expect(result.current.initialized).toBe(true)
    })
    
    // リフレッシュ
    await act(async () => {
      await result.current.refreshHistories()
    })
    
    expect(recipesApi.fetchRecipeHistories).toHaveBeenCalledTimes(2) // 初期化 + リフレッシュ
  })
})