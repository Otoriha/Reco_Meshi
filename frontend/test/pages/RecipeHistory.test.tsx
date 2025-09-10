import { render, screen, waitFor, fireEvent, act } from '@testing-library/react'
import React from 'react'
import RecipeHistory from '../../src/pages/RecipeHistory/RecipeHistory'
import type { RecipeHistory as RecipeHistoryType, PaginationMeta } from '../../src/types/recipe'

// モックデータ
const mockHistory1: RecipeHistoryType = {
  id: 1,
  user_id: 1,
  recipe_id: 10,
  cooked_at: '2025-01-15T12:00:00Z',
  memo: 'とてもおいしかった！',
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

const mockHistory2: RecipeHistoryType = {
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
  total_pages: 2,
  total_count: 25
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

describe('RecipeHistory Page', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockFetchRecipeHistories.mockResolvedValue({
      data: [mockHistory1, mockHistory2],
      meta: mockMeta
    })
  })

  it('初期表示時にローディングが表示され、データ取得後にリストが表示される', async () => {
    render(<RecipeHistory />)
    
    // ローディング表示の確認
    expect(screen.getByText('読み込み中...')).toBeInTheDocument()
    
    // データ取得後のリスト表示確認
    await waitFor(() => {
      expect(screen.getByText('レシピ履歴')).toBeInTheDocument()
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
      expect(screen.getByText('野菜炒め')).toBeInTheDocument()
    })
    
    expect(mockFetchRecipeHistories).toHaveBeenCalledWith({ per_page: 20, page: 1 })
  })

  it('フィルタ機能が正しく動作する', async () => {
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
    })
    
    // 期間フィルタを変更
    const periodSelect = screen.getByDisplayValue('すべて')
    fireEvent.change(periodSelect, { target: { value: 'this-week' } })
    
    // APIが新しいパラメータで呼ばれることを確認
    await waitFor(() => {
      expect(mockFetchRecipeHistories).toHaveBeenCalledWith(
        expect.objectContaining({
          per_page: 20,
          page: 1,
          start_date: expect.any(String)
        })
      )
    })
  })

  it('検索機能が正しく動作する', async () => {
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
      expect(screen.getByText('野菜炒め')).toBeInTheDocument()
    })
    
    // 検索語入力
    const searchInput = screen.getByPlaceholderText('レシピ名で検索...')
    fireEvent.change(searchInput, { target: { value: 'カレー' } })
    
    // クライアントサイドフィルタでカレーライスのみが表示される
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
      expect(screen.queryByText('野菜炒め')).not.toBeInTheDocument()
    })
  })

  it('評価フィルタが正しく動作する', async () => {
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
      expect(screen.getByText('野菜炒め')).toBeInTheDocument()
    })
    
    // 評価済みのみのフィルタを適用
    const ratingFilter = screen.getByDisplayValue('すべて表示')
    fireEvent.change(ratingFilter, { target: { value: 'true' } })
    
    // APIが新しいパラメータで呼ばれることを確認
    await waitFor(() => {
      expect(mockFetchRecipeHistories).toHaveBeenCalledWith(
        expect.objectContaining({
          per_page: 20,
          page: 1,
          rated_only: true
        })
      )
    })
  })

  it('レシピアイテムをクリックするとモーダルが開く', async () => {
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
    })
    
    // レシピアイテムをクリック
    const recipeItem = screen.getByText('カレーライス').closest('div')
    fireEvent.click(recipeItem!)
    
    // モーダルが開くことを確認
    await waitFor(() => {
      expect(screen.getByText('レシピ詳細')).toBeInTheDocument()
      expect(screen.getByDisplayValue('とてもおいしかった！')).toBeInTheDocument()
    })
  })

  it('モーダル内での評価・メモ更新が正しく動作する', async () => {
    const updatedHistory = { ...mockHistory1, rating: 4, memo: '更新されたメモ' }
    mockUpdateRecipeHistory.mockResolvedValue(updatedHistory)
    
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
    })
    
    // レシピアイテムをクリックしてモーダルを開く
    const recipeItem = screen.getByText('カレーライス').closest('div')
    fireEvent.click(recipeItem!)
    
    await waitFor(() => {
      expect(screen.getByText('レシピ詳細')).toBeInTheDocument()
    })
    
    // 評価を変更
    const rating4Button = screen.getByRole('button', { name: /4/i })
    fireEvent.click(rating4Button)
    
    // メモを変更
    const memoTextarea = screen.getByDisplayValue('とてもおいしかった！')
    fireEvent.change(memoTextarea, { target: { value: '更新されたメモ' } })
    
    // 更新ボタンをクリック
    const updateButton = screen.getByText('更新')
    await act(async () => {
      fireEvent.click(updateButton)
    })
    
    // API呼び出しの確認
    expect(mockUpdateRecipeHistory).toHaveBeenCalledWith(1, {
      rating: 4,
      memo: '更新されたメモ'
    })
  })

  it('モーダル内でのレシピ削除が正しく動作する', async () => {
    mockDeleteRecipeHistory.mockResolvedValue(undefined)
    
    // 削除後のデータ（mockHistory1が削除される）
    mockFetchRecipeHistories.mockResolvedValueOnce({
      data: [mockHistory1, mockHistory2],
      meta: mockMeta
    }).mockResolvedValueOnce({
      data: [mockHistory2],
      meta: { ...mockMeta, total_count: 24 }
    })
    
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
    })
    
    // レシピアイテムをクリックしてモーダルを開く
    const recipeItem = screen.getByText('カレーライス').closest('div')
    fireEvent.click(recipeItem!)
    
    await waitFor(() => {
      expect(screen.getByText('レシピ詳細')).toBeInTheDocument()
    })
    
    // 削除ボタンをクリック
    const deleteButton = screen.getByText('削除')
    await act(async () => {
      fireEvent.click(deleteButton)
    })
    
    // API呼び出しの確認
    expect(mockDeleteRecipeHistory).toHaveBeenCalledWith(1)
    
    // モーダルが閉じることを確認
    await waitFor(() => {
      expect(screen.queryByText('レシピ詳細')).not.toBeInTheDocument()
    })
  })

  it('ページネーションが正しく動作する', async () => {
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
    })
    
    // ページネーションのボタンが表示されることを確認
    expect(screen.getByText('1')).toBeInTheDocument()
    expect(screen.getByText('2')).toBeInTheDocument()
    expect(screen.getByText('次へ')).toBeInTheDocument()
    
    // 2ページ目に移動
    const page2Button = screen.getByText('2')
    fireEvent.click(page2Button)
    
    // 2ページ目のデータ取得APIが呼ばれることを確認
    await waitFor(() => {
      expect(mockFetchRecipeHistories).toHaveBeenCalledWith({
        per_page: 20,
        page: 2
      })
    })
  })

  it('フィルタクリア機能が正しく動作する', async () => {
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
    })
    
    // フィルタを設定
    const periodSelect = screen.getByDisplayValue('すべて')
    fireEvent.change(periodSelect, { target: { value: 'this-week' } })
    
    const ratingFilter = screen.getByDisplayValue('すべて表示')
    fireEvent.change(ratingFilter, { target: { value: 'true' } })
    
    const searchInput = screen.getByPlaceholderText('レシピ名で検索...')
    fireEvent.change(searchInput, { target: { value: 'カレー' } })
    
    // クリアボタンをクリック
    const clearButton = screen.getByText('クリア')
    fireEvent.click(clearButton)
    
    // フィルタがリセットされることを確認
    await waitFor(() => {
      expect(screen.getByDisplayValue('すべて')).toBeInTheDocument()
      expect(screen.getByDisplayValue('すべて表示')).toBeInTheDocument()
      expect((screen.getByPlaceholderText('レシピ名で検索...') as HTMLInputElement).value).toBe('')
    })
    
    // デフォルトパラメータでAPIが再呼び出しされることを確認
    expect(mockFetchRecipeHistories).toHaveBeenLastCalledWith({ per_page: 20, page: 1 })
  })

  it('エラー状態が正しく表示される', async () => {
    const errorMessage = 'データの取得に失敗しました'
    mockFetchRecipeHistories.mockRejectedValue(new Error(errorMessage))
    
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText(errorMessage)).toBeInTheDocument()
    })
  })

  it('データが空の場合のメッセージが表示される', async () => {
    mockFetchRecipeHistories.mockResolvedValue({
      data: [],
      meta: { current_page: 1, per_page: 20, total_pages: 0, total_count: 0 }
    })
    
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('レシピ履歴がありません')).toBeInTheDocument()
    })
  })

  it('モーダルのクローズボタンが正しく動作する', async () => {
    render(<RecipeHistory />)
    
    await waitFor(() => {
      expect(screen.getByText('カレーライス')).toBeInTheDocument()
    })
    
    // レシピアイテムをクリックしてモーダルを開く
    const recipeItem = screen.getByText('カレーライス').closest('div')
    fireEvent.click(recipeItem!)
    
    await waitFor(() => {
      expect(screen.getByText('レシピ詳細')).toBeInTheDocument()
    })
    
    // クローズボタンをクリック
    const closeButton = screen.getByText('×')
    fireEvent.click(closeButton)
    
    // モーダルが閉じることを確認
    await waitFor(() => {
      expect(screen.queryByText('レシピ詳細')).not.toBeInTheDocument()
    })
  })
})