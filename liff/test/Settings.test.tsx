import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { BrowserRouter } from 'react-router-dom'
import Settings from '../src/pages/Settings/Settings'
import * as usersApi from '../src/api/users'
import * as useAuthHook from '../src/hooks/useAuth'

vi.mock('../src/api/users')
vi.mock('../src/hooks/useAuth')

const mockLogout = vi.fn()

describe('Settings (LIFF)', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    vi.mocked(useAuthHook.useAuth).mockReturnValue({
      isInitialized: true,
      isAuthenticated: true,
      isInClient: true,
      user: { userId: 'U123', displayName: 'Test User', pictureUrl: undefined },
      login: vi.fn(),
      logout: mockLogout,
    })

    vi.mocked(usersApi.getUserProfile).mockResolvedValue({
      name: 'Test User',
      email: 'test@example.com',
      provider: 'line',
    })

    vi.mocked(usersApi.getUserSettings).mockResolvedValue({
      default_servings: 2,
      recipe_difficulty: 'medium',
      cooking_time: 30,
      shopping_frequency: '2-3日に1回',
    })
  })

  const renderSettings = () => {
    return render(
      <BrowserRouter>
        <Settings />
      </BrowserRouter>
    )
  }

  it('設定画面が表示される', async () => {
    renderSettings()

    await waitFor(() => {
      expect(usersApi.getUserProfile).toHaveBeenCalled()
      expect(usersApi.getUserSettings).toHaveBeenCalled()
    })
  })

  it('保存時にAPIが呼ばれる', async () => {
    const user = userEvent.setup()
    vi.mocked(usersApi.updateUserProfile).mockResolvedValue({
      message: 'プロフィールを更新しました',
    })
    vi.mocked(usersApi.updateUserSettings).mockResolvedValue({
      message: '設定を保存しました',
    })

    renderSettings()

    await waitFor(() => {
      expect(screen.getByRole('button', { name: '変更を保存' })).toBeInTheDocument()
    })

    const saveButton = screen.getByRole('button', { name: '変更を保存' })
    await user.click(saveButton)

    await waitFor(() => {
      expect(usersApi.updateUserProfile).toHaveBeenCalled()
      expect(usersApi.updateUserSettings).toHaveBeenCalled()
    })
  })
})
