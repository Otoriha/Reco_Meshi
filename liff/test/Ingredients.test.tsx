import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { BrowserRouter } from 'react-router-dom'
import Ingredients from '../src/pages/Ingredients/Ingredients'
import * as ingredientsApi from '../src/api/ingredients'
import * as imageRecognitionApi from '../src/api/imageRecognition'
import type { UserIngredientGroupedResponse, UserIngredient } from '../src/types/ingredient'
import { mockLiff } from './setup'

// API関数をモック
vi.mock('../src/api/ingredients', () => ({
  getUserIngredients: vi.fn(),
  updateUserIngredient: vi.fn(),
  deleteUserIngredient: vi.fn(),
}))

vi.mock('../src/api/imageRecognition', () => ({
  imageRecognitionApi: {
    recognizeIngredients: vi.fn(),
    recognizeMultipleIngredients: vi.fn(),
  },
}))

const mockGetUserIngredients = vi.mocked(ingredientsApi.getUserIngredients)
const mockUpdateUserIngredient = vi.mocked(ingredientsApi.updateUserIngredient)
const mockDeleteUserIngredient = vi.mocked(ingredientsApi.deleteUserIngredient)
const mockRecognizeIngredients = vi.mocked(imageRecognitionApi.imageRecognitionApi.recognizeIngredients)
const mockRecognizeMultipleIngredients = vi.mocked(
  imageRecognitionApi.imageRecognitionApi.recognizeMultipleIngredients
)

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

  describe('画像認識機能', () => {
    beforeEach(async () => {
      mockGetUserIngredients.mockResolvedValue(mockGroupedResponse)
      // デフォルトでLINEアプリ内とする
      mockLiff.isInClient.mockReturnValue(true)
    })

    it('LIFF環境チェックに応じたボタン文言の表示（LINEアプリ内）', async () => {
      mockLiff.isInClient.mockReturnValue(true)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('カメラで食材を追加')).toBeInTheDocument()
        expect(screen.getByText('カメラ起動')).toBeInTheDocument()
        expect(
          screen.getByText('冷蔵庫の写真を撮影すると、AIが自動で食材を認識します。')
        ).toBeInTheDocument()
      })
    })

    it('LIFF環境チェックに応じたボタン文言の表示（ブラウザ）', async () => {
      mockLiff.isInClient.mockReturnValue(false)

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('写真から食材を追加')).toBeInTheDocument()
        expect(screen.getByText('写真を選択')).toBeInTheDocument()
        expect(
          screen.getByText('冷蔵庫の写真を選択すると、AIが自動で食材を認識します。')
        ).toBeInTheDocument()
      })
    })

    it('単一画像アップロードの成功', async () => {
      mockLiff.isInClient.mockReturnValue(false)
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      mockRecognizeIngredients.mockResolvedValue({
        success: true,
        recognized_ingredients: [
          { name: 'トマト', confidence: 0.95 },
          { name: 'きゅうり', confidence: 0.88 },
        ],
      })

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('写真を選択')).toBeInTheDocument()
      })

      const fileInput = screen.getByRole('button', { name: '写真を選択' }).previousElementSibling as HTMLInputElement

      // ファイル選択をシミュレート
      Object.defineProperty(fileInput, 'files', {
        value: [mockFile],
        writable: false,
      })

      fireEvent.change(fileInput)

      await waitFor(() => {
        expect(mockRecognizeIngredients).toHaveBeenCalledWith(mockFile)
      })

      await waitFor(() => {
        expect(screen.getByText('識別された食材: トマト(95%)、きゅうり(88%)')).toBeInTheDocument()
      })

      // 在庫リストが再取得されることを確認
      expect(mockGetUserIngredients).toHaveBeenCalledTimes(2)
    })

    it('複数画像アップロードの成功', async () => {
      const mockFile1 = new File(['test1'], 'test1.jpg', { type: 'image/jpeg' })
      const mockFile2 = new File(['test2'], 'test2.jpg', { type: 'image/jpeg' })
      mockRecognizeMultipleIngredients.mockResolvedValue({
        success: true,
        recognized_ingredients: [{ name: 'にんじん', confidence: 0.92 }],
      })

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('カメラ起動')).toBeInTheDocument()
      })

      const fileInput = screen.getByRole('button', { name: 'カメラ起動' }).previousElementSibling as HTMLInputElement

      Object.defineProperty(fileInput, 'files', {
        value: [mockFile1, mockFile2],
        writable: false,
      })

      fireEvent.change(fileInput)

      await waitFor(() => {
        expect(mockRecognizeMultipleIngredients).toHaveBeenCalledWith([mockFile1, mockFile2])
      })

      await waitFor(() => {
        expect(screen.getByText('識別された食材: にんじん(92%)')).toBeInTheDocument()
      })
    })

    it('食材が認識できなかった場合のメッセージ表示', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      mockRecognizeIngredients.mockResolvedValue({
        success: true,
        recognized_ingredients: [],
      })

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('カメラ起動')).toBeInTheDocument()
      })

      const fileInput = screen.getByRole('button', { name: 'カメラ起動' }).previousElementSibling as HTMLInputElement

      Object.defineProperty(fileInput, 'files', {
        value: [mockFile],
        writable: false,
      })

      fireEvent.change(fileInput)

      await waitFor(() => {
        expect(screen.getByText('食材を識別できませんでした。写真を確認してください。')).toBeInTheDocument()
      })
    })

    it('ファイルサイズが20MBを超える場合のエラー', async () => {
      const largeFile = new File(['x'.repeat(21 * 1024 * 1024)], 'large.jpg', { type: 'image/jpeg' })

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('カメラ起動')).toBeInTheDocument()
      })

      const fileInput = screen.getByRole('button', { name: 'カメラ起動' }).previousElementSibling as HTMLInputElement

      Object.defineProperty(fileInput, 'files', {
        value: [largeFile],
        writable: false,
      })

      fireEvent.change(fileInput)

      await waitFor(() => {
        expect(screen.getByText('ファイルサイズは20MB以下にしてください。')).toBeInTheDocument()
      })

      expect(mockRecognizeIngredients).not.toHaveBeenCalled()
    })

    it('画像認識APIエラーの処理', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      mockRecognizeIngredients.mockRejectedValue(new Error('Network error'))

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('カメラ起動')).toBeInTheDocument()
      })

      const fileInput = screen.getByRole('button', { name: 'カメラ起動' }).previousElementSibling as HTMLInputElement

      Object.defineProperty(fileInput, 'files', {
        value: [mockFile],
        writable: false,
      })

      fireEvent.change(fileInput)

      await waitFor(() => {
        expect(screen.getByText('画像のアップロードに失敗しました。通信環境をご確認ください。')).toBeInTheDocument()
      })
    })

    it('画像認識失敗時のレスポンス処理', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      mockRecognizeIngredients.mockResolvedValue({
        success: false,
        recognized_ingredients: [],
        message: 'ファイル形式が不正です',
      })

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('カメラ起動')).toBeInTheDocument()
      })

      const fileInput = screen.getByRole('button', { name: 'カメラ起動' }).previousElementSibling as HTMLInputElement

      Object.defineProperty(fileInput, 'files', {
        value: [mockFile],
        writable: false,
      })

      fireEvent.change(fileInput)

      await waitFor(() => {
        expect(screen.getByText('ファイル形式が不正です')).toBeInTheDocument()
      })
    })

    it('アップロード中はボタンが無効化される', async () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
      mockRecognizeIngredients.mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve({ success: true, recognized_ingredients: [] }), 100))
      )

      render(<Ingredients />, { wrapper: IngredientsWrapper })

      await waitFor(() => {
        expect(screen.getByText('カメラ起動')).toBeInTheDocument()
      })

      const button = screen.getByRole('button', { name: 'カメラ起動' })
      const fileInput = button.previousElementSibling as HTMLInputElement

      Object.defineProperty(fileInput, 'files', {
        value: [mockFile],
        writable: false,
      })

      fireEvent.change(fileInput)

      await waitFor(() => {
        expect(screen.getByText('アップロード中...')).toBeInTheDocument()
        expect(screen.getByRole('button', { name: 'アップロード中...' })).toBeDisabled()
      })
    })
  })
})
