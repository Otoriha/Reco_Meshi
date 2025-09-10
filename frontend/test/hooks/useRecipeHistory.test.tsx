import { render, waitFor, act } from '@testing-library/react'
import React from 'react'
import { useRecipeHistory } from '../../src/hooks/useRecipeHistory'
import type { RecipeHistory, PaginationMeta } from '../../src/types/recipe'

// モックデータ
const mockHistory1: RecipeHistory = {
  id: 1,
  user_id: 1,
  recipe_id: 10,
  cooked_at: '2025-01-15T12:00:00Z',
  memo: 'おいしかった',
  rating: 5,
  created_at: '2025-01-15T12:00:00Z',
  updated_at: '2025-01-15T12:00:00Z',
  recipe: {
    id: 10,
    title: 'カレーライス',
    cooking_time: 30,
    difficulty: 'easy'
  }
}

const mockHistory2: RecipeHistory = {
  id: 2,
  user_id: 1,
  recipe_id: 20,
  cooked_at: '2025-01-14T18:00:00Z',
  memo: null,
  rating: null,
  created_at: '2025-01-14T18:00:00Z',
  updated_at: '2025-01-14T18:00:00Z',
  recipe: {
    id: 20,
    title: '野菜炒め',
    cooking_time: 15,
    difficulty: 'easy'
  }
}

const mockMeta: PaginationMeta = {
  current_page: 1,
  per_page: 20,
  total_pages: 1,
  total_count: 2
}

const mockFetchRecipeHistories = vi.fn()
const mockUpdateRecipeHistory = vi.fn()
const mockDeleteRecipeHistory = vi.fn()

vi.mock('../../src/api/recipes', () => ({
  recipesApi: {
    fetchRecipeHistories: (...args: any[]) => mockFetchRecipeHistories(...args),
    updateRecipeHistory: (...args: any[]) => mockUpdateRecipeHistory(...args),
    deleteRecipeHistory: (...args: any[]) => mockDeleteRecipeHistory(...args),
  }
}))

const TestComponent: React.FC = () => {
  const {
    histories,
    loading,
    error,
    initialized,
    fetchHistories,
    updateHistory,
    deleteHistory,
    currentPage,
    totalPages
  } = useRecipeHistory()

  return (
    <div>
      <div data-testid="loading">{loading.toString()}</div>
      <div data-testid="initialized">{initialized.toString()}</div>
      <div data-testid="error">{error || 'null'}</div>
      <div data-testid="histories-count">{histories.length}</div>
      <div data-testid="current-page">{currentPage}</div>
      <div data-testid="total-pages">{totalPages}</div>
      <button 
        data-testid="fetch-button" 
        onClick={() => fetchHistories()}
      >
        Fetch
      </button>
      <button 
        data-testid="update-button" 
        onClick={() => updateHistory(1, { rating: 4 })}
      >
        Update
      </button>
      <button 
        data-testid="delete-button" 
        onClick={() => deleteHistory(1)}
      >
        Delete
      </button>
    </div>
  )
}

describe('useRecipeHistory hook', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('初期状態が正しく設定される', () => {
    const { getByTestId } = render(<TestComponent />)
    
    expect(getByTestId('loading').textContent).toBe('false')
    expect(getByTestId('initialized').textContent).toBe('false')
    expect(getByTestId('error').textContent).toBe('null')
    expect(getByTestId('histories-count').textContent).toBe('0')
    expect(getByTestId('current-page').textContent).toBe('1')
    expect(getByTestId('total-pages').textContent).toBe('1')
  })

  it('データを正常に取得できる', async () => {
    mockFetchRecipeHistories.mockResolvedValue({
      data: [mockHistory1, mockHistory2],
      meta: mockMeta
    })

    const { getByTestId } = render(<TestComponent />)
    
    act(() => {
      getByTestId('fetch-button').click()
    })

    // ローディング状態をチェック
    expect(getByTestId('loading').textContent).toBe('true')

    await waitFor(() => {
      expect(getByTestId('loading').textContent).toBe('false')
      expect(getByTestId('initialized').textContent).toBe('true')
      expect(getByTestId('histories-count').textContent).toBe('2')
      expect(getByTestId('current-page').textContent).toBe('1')
      expect(getByTestId('total-pages').textContent).toBe('1')
    })

    expect(mockFetchRecipeHistories).toHaveBeenCalledWith({ per_page: 20, page: 1 })
  })

  it('エラーが正しくハンドリングされる', async () => {
    const errorMessage = 'ネットワークエラー'
    mockFetchRecipeHistories.mockRejectedValue(new Error(errorMessage))

    const { getByTestId } = render(<TestComponent />)
    
    act(() => {
      getByTestId('fetch-button').click()
    })

    await waitFor(() => {
      expect(getByTestId('loading').textContent).toBe('false')
      expect(getByTestId('initialized').textContent).toBe('true')
      expect(getByTestId('error').textContent).toBe(errorMessage)
    })
  })

  it('履歴を正常に更新できる', async () => {
    const updatedHistory = { ...mockHistory1, rating: 4 }
    mockUpdateRecipeHistory.mockResolvedValue(updatedHistory)
    
    mockFetchRecipeHistories.mockResolvedValue({
      data: [mockHistory1],
      meta: { ...mockMeta, total_count: 1 }
    })

    const { getByTestId } = render(<TestComponent />)
    
    // 最初にデータを取得
    act(() => {
      getByTestId('fetch-button').click()
    })

    await waitFor(() => {
      expect(getByTestId('histories-count').textContent).toBe('1')
    })

    // 更新を実行
    await act(async () => {
      getByTestId('update-button').click()
    })

    expect(mockUpdateRecipeHistory).toHaveBeenCalledWith(1, { rating: 4 })
  })

  it('履歴を正常に削除できる', async () => {
    mockDeleteRecipeHistory.mockResolvedValue(undefined)
    
    mockFetchRecipeHistories.mockResolvedValue({
      data: [mockHistory1, mockHistory2],
      meta: mockMeta
    })

    const { getByTestId } = render(<TestComponent />)
    
    // 最初にデータを取得
    act(() => {
      getByTestId('fetch-button').click()
    })

    await waitFor(() => {
      expect(getByTestId('histories-count').textContent).toBe('2')
    })

    // 削除を実行
    await act(async () => {
      getByTestId('delete-button').click()
    })

    expect(mockDeleteRecipeHistory).toHaveBeenCalledWith(1)
    
    await waitFor(() => {
      expect(getByTestId('histories-count').textContent).toBe('1')
    })
  })

  it('パラメータを指定してデータを取得できる', async () => {
    mockFetchRecipeHistories.mockResolvedValue({
      data: [mockHistory1],
      meta: { ...mockMeta, total_count: 1 }
    })

    const TestComponentWithParams: React.FC = () => {
      const { fetchHistories } = useRecipeHistory()
      
      return (
        <button 
          data-testid="fetch-with-params-button" 
          onClick={() => fetchHistories({ page: 2, per_page: 10, rated_only: true })}
        >
          Fetch with params
        </button>
      )
    }

    const { getByTestId } = render(<TestComponentWithParams />)
    
    act(() => {
      getByTestId('fetch-with-params-button').click()
    })

    await waitFor(() => {
      expect(mockFetchRecipeHistories).toHaveBeenCalledWith({ 
        per_page: 10, 
        page: 2, 
        rated_only: true 
      })
    })
  })
})