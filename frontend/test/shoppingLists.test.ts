import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'
import React from 'react'
import { MemoryRouter } from 'react-router-dom'
import ShoppingLists from '../src/pages/ShoppingLists/ShoppingLists'
import ShoppingListDetail from '../src/pages/ShoppingLists/ShoppingListDetail'
import * as shoppingListsApi from '../src/api/shoppingLists'
import type { ShoppingListSummary, ShoppingList } from '../src/types/shoppingList'

// APIクライアントのモック
vi.mock('../src/api/client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn()
  }
}))

// useParamsのモック
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useParams: vi.fn(() => ({ id: '1' })),
    useNavigate: vi.fn(() => vi.fn())
  }
})

const flushAsync = async () => {
  await act(async () => {
    await Promise.resolve()
  })
  await act(async () => {
    await Promise.resolve()
  })
}

describe('ShoppingLists Component', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('買い物リスト一覧を表示する', async () => {
    const mockShoppingLists: ShoppingListSummary[] = [
      {
        id: 1,
        displayTitle: 'テスト買い物リスト1',
        status: 'pending',
        statusDisplay: '作成済み',
        completionPercentage: 50,
        totalItemsCount: 10,
        uncheckedItemsCount: 5,
        canBeCompleted: false,
        createdAt: '2024-01-01T10:00:00Z',
        recipe: {
          id: 1,
          title: 'テストレシピ'
        }
      },
      {
        id: 2,
        displayTitle: 'テスト買い物リスト2',
        status: 'in_progress',
        statusDisplay: '買い物中',
        completionPercentage: 80,
        totalItemsCount: 5,
        uncheckedItemsCount: 1,
        canBeCompleted: false,
        createdAt: '2024-01-02T10:00:00Z',
        recipe: null
      }
    ]

    vi.spyOn(shoppingListsApi, 'getShoppingLists')
      .mockResolvedValueOnce(mockShoppingLists.filter(list => list.status === 'pending'))
      .mockResolvedValueOnce(mockShoppingLists.filter(list => list.status === 'in_progress'))

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingLists)
      )
    )

    // ローディング状態の確認
    expect(screen.getByText('読み込み中...')).toBeInTheDocument()

    // データ取得後の表示確認
    await waitFor(() => {
      expect(screen.getByText('テスト買い物リスト1')).toBeInTheDocument()
      expect(screen.getByText('テスト買い物リスト2')).toBeInTheDocument()
    })

    // ステータスとレシピの表示確認
    expect(screen.getByText('作成済み')).toBeInTheDocument()
    expect(screen.getByText('買い物中')).toBeInTheDocument()
    expect(screen.getByText('レシピ: テストレシピ')).toBeInTheDocument()

    // 進捗の表示確認
    expect(screen.getByText('進捗: 5 / 10 項目')).toBeInTheDocument()
    expect(screen.getByText('50% 完了')).toBeInTheDocument()
  })

  it('エラー時にエラーメッセージを表示する', async () => {
    const mockError = new Error('Network error')
    vi.spyOn(shoppingListsApi, 'getShoppingLists').mockRejectedValue(mockError)

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingLists)
      )
    )

    await waitFor(() => {
      expect(screen.getByText(/予期しないエラーが発生しました/)).toBeInTheDocument()
      expect(screen.getByText('再試行')).toBeInTheDocument()
    })
  })

  it('ポーリングが設定された間隔で実行される', async () => {
    vi.useFakeTimers()
    const mockShoppingLists: ShoppingListSummary[] = []
    const getSpy = vi.spyOn(shoppingListsApi, 'getShoppingLists')
      .mockResolvedValue(mockShoppingLists)

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingLists)
      )
    )

    // 初回の呼び出し（pending と in_progress の2回）
    await flushAsync()
    expect(getSpy).toHaveBeenCalledTimes(2)

    // 30秒後のポーリング
    vi.advanceTimersByTime(30000)
    await flushAsync()
    expect(getSpy).toHaveBeenCalledTimes(4) // 初回2回 + ポーリング2回
  })
})

describe('ShoppingListDetail Component', () => {
  const mockShoppingList: ShoppingList = {
    id: 1,
    displayTitle: 'テスト買い物リスト',
    status: 'in_progress',
    statusDisplay: '買い物中',
    completionPercentage: 50,
    totalItemsCount: 2,
    uncheckedItemsCount: 1,
    canBeCompleted: false,
    createdAt: '2024-01-01T10:00:00Z',
    updatedAt: '2024-01-01T12:00:00Z',
    title: null,
    note: 'テストメモ',
    recipe: {
      id: 1,
      title: 'テストレシピ',
      description: null,
      servings: 4
    },
    shoppingListItems: [
      {
        id: 1,
        quantity: 2,
        unit: '個',
        isChecked: false,
        checkedAt: null,
        lockVersion: 1,
        displayQuantityWithUnit: '2個',
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T10:00:00Z',
        ingredient: {
          id: 1,
          name: 'にんじん',
          category: '野菜',
          displayName: 'にんじん',
          displayNameWithEmoji: '🥕 にんじん'
        }
      },
      {
        id: 2,
        quantity: 1,
        unit: '本',
        isChecked: true,
        checkedAt: '2024-01-01T11:00:00Z',
        lockVersion: 2,
        displayQuantityWithUnit: '1本',
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T11:00:00Z',
        ingredient: {
          id: 2,
          name: 'だいこん',
          category: '野菜',
          displayName: 'だいこん',
          displayNameWithEmoji: '🥬 だいこん'
        }
      }
    ]
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('買い物リスト詳細を表示する', async () => {
    vi.spyOn(shoppingListsApi, 'getShoppingList').mockResolvedValue(mockShoppingList)

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingListDetail)
      )
    )

    await waitFor(() => {
      expect(screen.getByText('テスト買い物リスト')).toBeInTheDocument()
      expect(screen.getByText('レシピ: テストレシピ')).toBeInTheDocument()
      expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
      expect(screen.getByText('🥬 だいこん')).toBeInTheDocument()
      expect(screen.getByText('2個')).toBeInTheDocument()
      expect(screen.getByText('1本')).toBeInTheDocument()
    })

    // チェックボックスの状態確認
    const checkboxes = screen.getAllByRole('checkbox')
    expect(checkboxes[0]).not.toBeChecked()
    expect(checkboxes[1]).toBeChecked()

    // 進捗の表示確認
    expect(screen.getByText('進捗: 1 / 2 項目')).toBeInTheDocument()
    expect(screen.getByText('50%')).toBeInTheDocument()

    // メモの表示確認
    expect(screen.getByText('テストメモ')).toBeInTheDocument()
  })

  it('チェックボックスの操作で楽観的更新が動作する', async () => {
    vi.spyOn(shoppingListsApi, 'getShoppingList').mockResolvedValue(mockShoppingList)
    const updateSpy = vi.spyOn(shoppingListsApi, 'updateShoppingListItem').mockResolvedValue({
      ...mockShoppingList.shoppingListItems![0],
      isChecked: true,
      checkedAt: '2024-01-01T13:00:00Z'
    })

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingListDetail)
      )
    )

    await waitFor(() => {
      expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
    })

    const checkbox = screen.getAllByRole('checkbox')[0]
    
    // チェックボックスをクリック
    fireEvent.click(checkbox)

    // 楽観的更新により即座にチェック状態が変わる
    expect(checkbox).toBeChecked()

    // API呼び出しの確認
    await waitFor(() => {
      expect(updateSpy).toHaveBeenCalledWith(1, 1, {
        isChecked: true,
        lockVersion: 1
      })
    })
  })

  it('409エラー時に適切なエラーメッセージを表示する', async () => {
    vi.spyOn(shoppingListsApi, 'getShoppingList').mockResolvedValue(mockShoppingList)
    
    const error409 = {
      response: { status: 409 }
    }
    vi.spyOn(shoppingListsApi, 'updateShoppingListItem').mockRejectedValue(error409)

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingListDetail)
      )
    )

    await waitFor(() => {
      expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
    })

    const checkbox = screen.getAllByRole('checkbox')[0]
    fireEvent.click(checkbox)

    await waitFor(() => {
      expect(screen.getByText(/他のユーザーによって更新されています/)).toBeInTheDocument()
      expect(screen.getByText('最新の状態を取得')).toBeInTheDocument()
    })

    // エラー後、チェックボックスは元の状態に戻る
    expect(checkbox).not.toBeChecked()
  })

  it('完了ボタンが条件を満たした時のみ表示される', async () => {
    const completableList = {
      ...mockShoppingList,
      canBeCompleted: true,
      uncheckedItemsCount: 0,
      completionPercentage: 100,
      shoppingListItems: mockShoppingList.shoppingListItems?.map(item => ({
        ...item,
        isChecked: true,
        checkedAt: '2024-01-01T11:00:00Z'
      }))
    }

    vi.spyOn(shoppingListsApi, 'getShoppingList').mockResolvedValue(completableList)

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingListDetail)
      )
    )

    await waitFor(() => {
      expect(screen.getByText('買い物完了（在庫に反映）')).toBeInTheDocument()
    })
  })

  it('完了処理が正常に動作する', async () => {
    vi.useFakeTimers()
    const completableList = {
      ...mockShoppingList,
      canBeCompleted: true,
      uncheckedItemsCount: 0,
      completionPercentage: 100,
      shoppingListItems: mockShoppingList.shoppingListItems?.map(item => ({
        ...item,
        isChecked: true,
        checkedAt: '2024-01-01T11:00:00Z'
      }))
    }

    vi.spyOn(shoppingListsApi, 'getShoppingList').mockResolvedValue(completableList)
    const completeSpy = vi.spyOn(shoppingListsApi, 'completeShoppingList').mockResolvedValue({
      ...completableList,
      status: 'completed' as const,
      statusDisplay: '完了'
    })

    const mockNavigate = vi.fn()
    vi.mocked(await import('react-router-dom')).useNavigate.mockReturnValue(mockNavigate)

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingListDetail)
      )
    )

    await flushAsync()
    const completeButton = screen.getByText('買い物完了（在庫に反映）')
    fireEvent.click(completeButton)

    await flushAsync()
    expect(completeSpy).toHaveBeenCalledWith(1)

    // 1.5秒後にナビゲート
    vi.advanceTimersByTime(1500)
    await flushAsync()
    expect(mockNavigate).toHaveBeenCalledWith('/shopping-lists')
  })

  it('ポーリングが編集中のアイテムを上書きしない', async () => {
    vi.useFakeTimers()
    const getSpy = vi.spyOn(shoppingListsApi, 'getShoppingList')
      .mockResolvedValue(mockShoppingList)

    vi.spyOn(shoppingListsApi, 'updateShoppingListItem').mockImplementation(
      () => new Promise(resolve => setTimeout(() => resolve({
        ...mockShoppingList.shoppingListItems![0],
        isChecked: true
      }), 1000))
    )

    render(
      React.createElement(MemoryRouter, null,
        React.createElement(ShoppingListDetail)
      )
    )

    await flushAsync()
    expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()

    const checkbox = screen.getAllByRole('checkbox')[0]
    fireEvent.click(checkbox)

    // チェックボックスが楽観的更新でチェック状態になる
    expect(checkbox).toBeChecked()

    // ポーリングが発生
    vi.advanceTimersByTime(15000)

    // ポーリング中でも編集中のアイテムはチェック状態を維持
    await flushAsync()
    expect(checkbox).toBeChecked()

    expect(getSpy).toHaveBeenCalledTimes(2) // 初回 + ポーリング1回
  })
})
