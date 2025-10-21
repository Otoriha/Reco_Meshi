import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { BrowserRouter } from 'react-router-dom'
import Settings from '../src/pages/Settings/Settings'
import * as usersApi from '../src/api/users'
import * as useAuthHook from '../src/hooks/useAuth'
import * as useToastHook from '../src/hooks/useToast'
import * as allergyIngredientsApi from '../src/api/allergyIngredients'
import * as dislikedIngredientsApi from '../src/api/dislikedIngredients'
import { AnalyticsProvider } from '../src/contexts/AnalyticsContext'

vi.mock('../src/api/users')
vi.mock('../src/hooks/useAuth')
vi.mock('../src/hooks/useToast')
vi.mock('../src/api/allergyIngredients')
vi.mock('../src/api/dislikedIngredients')

const mockShowToast = vi.fn()
const mockLogout = vi.fn()

describe('Settings', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    vi.mocked(useAuthHook.useAuth).mockReturnValue({
      isLoggedIn: true,
      isAuthResolved: true,
      user: { id: 1, name: 'Test User', email: 'test@example.com', created_at: '', updated_at: '' },
      login: vi.fn(),
      logout: mockLogout,
      setAuthState: vi.fn(),
    })

    vi.mocked(useToastHook.useToast).mockReturnValue({
      toast: null,
      showToast: mockShowToast,
      hideToast: vi.fn(),
      showSuccess: vi.fn(),
      showError: vi.fn(),
      showInfo: vi.fn(),
    })

    vi.mocked(usersApi.getUserProfile).mockResolvedValue({
      name: 'Test User',
      email: 'test@example.com',
      provider: 'email',
    })

    vi.mocked(usersApi.getUserSettings).mockResolvedValue({
      default_servings: 2,
      recipe_difficulty: 'medium',
      cooking_time: 30,
      shopping_frequency: '2-3日に1回',
      inventory_reminder_enabled: false,
      inventory_reminder_time: '09:00',
    })

    vi.mocked(allergyIngredientsApi.getAllergyIngredients).mockResolvedValue([])
    vi.mocked(dislikedIngredientsApi.getDislikedIngredients).mockResolvedValue([])
  })

  const renderSettings = () => {
    return render(
      <BrowserRouter>
        <AnalyticsProvider>
          <Settings />
        </AnalyticsProvider>
      </BrowserRouter>
    )
  }

  it('設定画面が表示され、プロフィールと設定データが取得される', async () => {
    renderSettings()

    await waitFor(() => {
      expect(usersApi.getUserProfile).toHaveBeenCalled()
      expect(usersApi.getUserSettings).toHaveBeenCalled()
    })
  })

  it('基本設定の保存が正常に動作する', async () => {
    const user = userEvent.setup()
    vi.mocked(usersApi.updateUserSettings).mockResolvedValue({
      message: '設定を保存しました',
    })

    renderSettings()

    // データ読み込み完了を待つ
    await waitFor(() => {
      expect(usersApi.getUserProfile).toHaveBeenCalled()
      expect(usersApi.getUserSettings).toHaveBeenCalled()
    })

    await waitFor(() => {
      expect(screen.getByRole('button', { name: '変更を保存' })).toBeInTheDocument()
    })

    const saveButton = screen.getByRole('button', { name: '変更を保存' })
    await user.click(saveButton)

    await waitFor(() => {
      expect(usersApi.updateUserSettings).toHaveBeenCalledWith({
        default_servings: 2,
        recipe_difficulty: 'medium',
        cooking_time: 30,
        shopping_frequency: '2-3日に1回',
        inventory_reminder_enabled: false,
        inventory_reminder_time: '09:00',
      })
      expect(mockShowToast).toHaveBeenCalledWith('設定を保存しました', 'success')
    })
  })

  it('通知設定タブが表示され、設定を変更できる', async () => {
    const user = userEvent.setup()
    vi.mocked(usersApi.updateUserSettings).mockResolvedValue({
      message: '設定を保存しました',
    })

    renderSettings()

    // データ読み込み完了を待つ
    await waitFor(() => {
      expect(usersApi.getUserProfile).toHaveBeenCalled()
      expect(usersApi.getUserSettings).toHaveBeenCalled()
    })

    // 通知設定タブに切り替え
    const notificationTab = screen.getByRole('button', { name: '通知設定' })
    await user.click(notificationTab)

    // 通知設定のUI要素が表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('在庫確認リマインダー')).toBeInTheDocument()
    })

    // 保存ボタンをクリック
    const saveButton = screen.getByRole('button', { name: '変更を保存' })
    await user.click(saveButton)

    // updateUserSettingsが呼ばれることを確認
    await waitFor(() => {
      expect(usersApi.updateUserSettings).toHaveBeenCalled()
      expect(mockShowToast).toHaveBeenCalledWith('設定を保存しました', 'success')
    })
  })

  it('422エラー時にバリデーションエラーが表示される（基本設定）', async () => {
    const user = userEvent.setup()
    vi.mocked(usersApi.updateUserSettings).mockRejectedValue({
      response: {
        status: 422,
        data: {
          errors: {
            default_servings: ['人数は1以上10以下で入力してください'],
          },
        },
      },
    })

    renderSettings()

    // データ読み込み完了を待つ
    await waitFor(() => {
      expect(usersApi.getUserProfile).toHaveBeenCalled()
      expect(usersApi.getUserSettings).toHaveBeenCalled()
    })

    await waitFor(() => {
      expect(screen.getByRole('button', { name: '変更を保存' })).toBeInTheDocument()
    })

    const saveButton = screen.getByRole('button', { name: '変更を保存' })
    await user.click(saveButton)

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith('入力内容を確認してください', 'error')
    })
  })

  it('401エラー時にログアウト処理が実行される（基本設定保存時）', async () => {
    const user = userEvent.setup()
    vi.mocked(usersApi.updateUserSettings).mockRejectedValue({
      response: {
        status: 401,
      },
    })

    renderSettings()

    // データ読み込み完了を待つ
    await waitFor(() => {
      expect(usersApi.getUserProfile).toHaveBeenCalled()
      expect(usersApi.getUserSettings).toHaveBeenCalled()
    })

    await waitFor(() => {
      expect(screen.getByRole('button', { name: '変更を保存' })).toBeInTheDocument()
    })

    const saveButton = screen.getByRole('button', { name: '変更を保存' })
    await user.click(saveButton)

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith('セッションが切れました。再度ログインしてください', 'error')
      expect(mockLogout).toHaveBeenCalled()
    })
  })

  it('401エラー時にログアウト処理が実行される（データ取得時）', async () => {
    vi.mocked(usersApi.getUserProfile).mockRejectedValue({
      response: {
        status: 401,
      },
    })

    renderSettings()

    await waitFor(() => {
      expect(mockShowToast).toHaveBeenCalledWith('セッションが切れました。再度ログインしてください', 'error')
      expect(mockLogout).toHaveBeenCalled()
    })
  })

  it('updateUserProfileが正しく呼ばれる', async () => {
    const user = userEvent.setup()
    vi.mocked(usersApi.updateUserProfile).mockResolvedValue({
      message: 'プロフィールを更新しました',
    })

    renderSettings()

    // データ読み込み完了を待つ
    await waitFor(() => {
      expect(usersApi.getUserProfile).toHaveBeenCalled()
      expect(usersApi.getUserSettings).toHaveBeenCalled()
    })

    // プロフィールタブに切り替え
    const profileTab = screen.getByRole('button', { name: 'プロフィール' })
    await user.click(profileTab)

    // 保存ボタンをクリック
    await waitFor(() => {
      expect(screen.getByRole('button', { name: '変更を保存' })).toBeInTheDocument()
    })

    const saveButton = screen.getByRole('button', { name: '変更を保存' })
    await user.click(saveButton)

    // updateUserProfileが呼ばれることを確認
    await waitFor(() => {
      expect(usersApi.updateUserProfile).toHaveBeenCalled()
      expect(mockShowToast).toHaveBeenCalledWith('プロフィールを更新しました', 'success')
    })
  })
})
