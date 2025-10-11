import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { BrowserRouter } from 'react-router-dom'
import Ingredients from '../src/pages/Ingredients/Ingredients'
import * as ingredientsApi from '../src/api/ingredients'
import type { UserIngredientGroupedResponse, UserIngredient } from '../src/types/ingredient'

// API関数をモック
vi.mock('../src/api/ingredients', () => ({
  getUserIngredients: vi.fn(),
  updateUserIngredient: vi.fn(),
  deleteUserIngredient: vi.fn(),
}))

const mockGetUserIngredients = vi.mocked(ingredientsApi.getUserIngredients)
const mockUpdateUserIngredient = vi.mocked(ingredientsApi.updateUserIngredient)
const mockDeleteUserIngredient = vi.mocked(ingredientsApi.deleteUserIngredient)

// window.confirmをモック（安全にプロパティを差し替え）
let confirmSpy: unknown

// テストデータ
const mockUserIngredient: UserIngredient = {
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

const mockExpiredIngredient: UserIngredient = {
  ...mockUserIngredient,
  id: 2,
  ingredient_id: 2,
  expiry_date: '2024-08-20',
  days_until_expiry: -6,
  expired: true,
  expiring_soon: false,
  ingredient: {
    id: 2,
    name: 'トマト',
    category: '野菜',
    unit: '個',
    emoji: '🍅',
    display_name_with_emoji: '🍅 トマト',
    created_at: '2024-08-26T00:00:00Z',
    updated_at: '2024-08-26T00:00:00Z',
  },
  display_name: '🍅 トマト',
  formatted_quantity: '2.5個',
}

const mockGroupedResponse: UserIngredientGroupedResponse = {
  status: { code: 200, message: '在庫を取得しました。' },
  data: {
    '野菜': [mockUserIngredient, mockExpiredIngredient],
  },
}

// テスト用のWrapper コンポーネント
const IngredientsWrapper = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>{children}</BrowserRouter>
)

describe('Ingredients Component', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // window.confirm を安全にモック
    if ('confirm' in window) {
      // @ts-expect-error - vitestの型互換でspyOn使用
      confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(false)
    } else {
      Object.defineProperty(window, 'confirm', {
        value: vi.fn().mockReturnValue(false),
        writable: true,
        configurable: true,
      })
      confirmSpy = window.confirm as unknown
    }
  })

  describe('初期表示', () => {
    it('ローディング状態を表示', async () => {
      mockGetUserIngredients.mockImplementation(() => new Promise(() => {})) // Pending状態

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      expect(screen.getByText('読み込み中...')).toBeInTheDocument()
    })

    it('食材がない場合の表示', async () => {
      mockGetUserIngredients.mockResolvedValue({
        status: { code: 200, message: '在庫を取得しました。' },
        data: {},
      } as UserIngredientGroupedResponse)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('食材がありません。')).toBeInTheDocument()
      })
    })

    it('食材リストの正常表示', async () => {
      mockGetUserIngredients.mockResolvedValue(mockGroupedResponse)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('野菜')).toBeInTheDocument()
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
        expect(screen.getByText('🍅 トマト')).toBeInTheDocument()
        expect(screen.getByText('2.5本')).toBeInTheDocument()
      })
    })

    it('期限切れ食材の警告表示', async () => {
      mockGetUserIngredients.mockResolvedValue(mockGroupedResponse)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        const expiredCard = screen.getByText('🍅 トマト').closest('div.border')
        expect(expiredCard).toHaveClass('bg-red-50', 'border-red-200')
      })
    })

    it('期限間近食材の警告表示', async () => {
      mockGetUserIngredients.mockResolvedValue(mockGroupedResponse)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        const soonCard = screen.getByText('🥕 にんじん').closest('div.border')
        expect(soonCard).toHaveClass('bg-yellow-50', 'border-yellow-200')
        expect(screen.getByText('期限まで 4 日')).toBeInTheDocument()
      })
    })

    it('API取得エラーの表示', async () => {
      mockGetUserIngredients.mockRejectedValue(new Error('Network Error'))

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('在庫の取得に失敗しました。通信環境をご確認ください。')).toBeInTheDocument()
      })
    })
  })

  describe('編集機能', () => {
    beforeEach(async () => {
      mockGetUserIngredients.mockResolvedValue(mockGroupedResponse)
    })

    it('編集ボタンクリックで編集モードに切り替わる', async () => {
      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
      })

      const editButton = screen.getAllByText('編集')[0]
      fireEvent.click(editButton)

      expect(screen.getByDisplayValue('2.5')).toBeInTheDocument()
      expect(screen.getByText('保存')).toBeInTheDocument()
      expect(screen.getByText('キャンセル')).toBeInTheDocument()
    })

    it('編集キャンセル', async () => {
      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
      })

      const editButton = screen.getAllByText('編集')[0]
      fireEvent.click(editButton)

      const cancelButton = screen.getByText('キャンセル')
      fireEvent.click(cancelButton)

      expect(screen.queryByDisplayValue('2.5')).not.toBeInTheDocument()
      expect(screen.getAllByText('編集')[0]).toBeInTheDocument()
    })

    it('数量更新の成功', async () => {
      const updatedIngredient = { ...mockUserIngredient, quantity: 3.0, formatted_quantity: '3本' }
      mockUpdateUserIngredient.mockResolvedValue({
        status: { code: 200, message: '在庫を更新しました。' },
        data: updatedIngredient,
      })

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
      })

      // 編集モード開始
      const editButton = screen.getAllByText('編集')[0]
      fireEvent.click(editButton)

      // 数値を変更
      const input = screen.getByDisplayValue('2.5')
      await userEvent.clear(input)
      await userEvent.type(input, '3')

      // 保存
      const saveButton = screen.getByText('保存')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(mockUpdateUserIngredient).toHaveBeenCalledWith(1, { quantity: 3 })
      })
    })

    it('無効な数量の入力エラー', async () => {
      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
      })

      // 編集モード開始
      const editButton = screen.getAllByText('編集')[0]
      fireEvent.click(editButton)

      // 無効な値を入力
      const input = screen.getByDisplayValue('2.5')
      await userEvent.clear(input)
      await userEvent.type(input, '0')

      // 保存試行
      const saveButton = screen.getByText('保存')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(screen.getByText('数量は0より大きい数値で入力してください。')).toBeInTheDocument()
      })
      expect(mockUpdateUserIngredient).not.toHaveBeenCalled()
    })

    it('更新APIエラーの処理', async () => {
      mockUpdateUserIngredient.mockRejectedValue(new Error('Update failed'))

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
      })

      // 編集と保存
      const editButton = screen.getAllByText('編集')[0]
      fireEvent.click(editButton)

      const input = screen.getByDisplayValue('2.5')
      await userEvent.clear(input)
      await userEvent.type(input, '3')

      const saveButton = screen.getByText('保存')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(screen.getByText('更新に失敗しました。時間をおいて再度お試しください。')).toBeInTheDocument()
      })
    })
  })

  describe('削除機能', () => {
    beforeEach(async () => {
      mockGetUserIngredients.mockResolvedValue(mockGroupedResponse)
    })

    it('削除確認でキャンセル', async () => {
      ;(confirmSpy as unknown).mockReturnValue(false)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
      })

      const deleteButton = screen.getAllByText('削除')[0]
      fireEvent.click(deleteButton)

      expect(window.confirm).toHaveBeenCalledWith('この食材を削除しますか？')
      expect(mockDeleteUserIngredient).not.toHaveBeenCalled()
    })

    it('削除実行の成功', async () => {
      ;(confirmSpy as unknown).mockReturnValue(true)
      mockDeleteUserIngredient.mockResolvedValue(undefined)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
        expect(screen.getByText('🍅 トマト')).toBeInTheDocument()
      })

      const deleteButton = screen.getAllByText('削除')[0]
      fireEvent.click(deleteButton)

      await waitFor(() => {
        expect(mockDeleteUserIngredient).toHaveBeenCalledWith(1)
      })

      // UIから削除されたことを確認
      await waitFor(() => {
        expect(screen.queryByText('🥕 にんじん')).not.toBeInTheDocument()
        expect(screen.getByText('🍅 トマト')).toBeInTheDocument() // 他は残る
      })
    })

    it('カテゴリ内最後の食材削除でカテゴリも削除', async () => {
      const singleItemResponse: UserIngredientGroupedResponse = {
        status: { code: 200, message: '在庫を取得しました。' },
        data: {
          '野菜': [mockUserIngredient],
        },
      }
      mockGetUserIngredients.mockResolvedValue(singleItemResponse)
      ;(confirmSpy as unknown).mockReturnValue(true)
      mockDeleteUserIngredient.mockResolvedValue(undefined)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
        expect(screen.getByText('野菜')).toBeInTheDocument()
      })

      const deleteButton = screen.getByText('削除')
      fireEvent.click(deleteButton)

      await waitFor(() => {
        expect(screen.getByText('食材がありません。')).toBeInTheDocument()
        expect(screen.queryByText('野菜')).not.toBeInTheDocument()
      })
    })

    it('削除APIエラーの処理', async () => {
      ;(confirmSpy as unknown).mockReturnValue(true)
      mockDeleteUserIngredient.mockRejectedValue(new Error('Delete failed'))

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
      })

      const deleteButton = screen.getAllByText('削除')[0]
      fireEvent.click(deleteButton)

      await waitFor(() => {
        expect(screen.getByText('削除に失敗しました。')).toBeInTheDocument()
      })
      // 削除失敗時はUIから削除されない
      expect(screen.getByText('🥕 にんじん')).toBeInTheDocument()
    })
  })

  describe('ingredient がnullの場合の処理', () => {
    it('ingredientがnullの場合display_nameを使用', async () => {
      const ingredientWithoutDetails = {
        ...mockUserIngredient,
        ingredient: null,
        display_name: 'Unknown Ingredient',
      }
      const responseWithNull: UserIngredientGroupedResponse = {
        status: { code: 200, message: '在庫を取得しました。' },
        data: {
          'その他': [ingredientWithoutDetails],
        },
      }
      mockGetUserIngredients.mockResolvedValue(responseWithNull)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('Unknown Ingredient')).toBeInTheDocument()
        expect(screen.getByText('その他')).toBeInTheDocument()
      })
    })
  })
})
