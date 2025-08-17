import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import Login from '../src/pages/Auth/Login'
import { AuthProvider } from '../src/contexts/AuthContext'
import * as authApi from '../src/api/auth'
import * as useAuthHook from '../src/hooks/useAuth'

// auth.tsとuseAuthをモック
vi.mock('../src/api/auth', () => ({
  login: vi.fn(),
  isAuthenticated: vi.fn(),
  logout: vi.fn(),
}))

vi.mock('../src/hooks/useAuth', () => ({
  useAuth: vi.fn(),
}))

const mockLogin = vi.fn()
const mockUseAuth = {
  isLoggedIn: false,
  user: null,
  login: mockLogin,
  logout: vi.fn(),
  setAuthState: vi.fn(),
}

describe('Login', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(useAuthHook.useAuth).mockReturnValue(mockUseAuth)
  })

  it('ログインフォームが正しく表示される', () => {
    render(
      <AuthProvider>
        <Login />
      </AuthProvider>
    )

    expect(screen.getByRole('heading', { name: 'ログイン' })).toBeInTheDocument()
    expect(screen.getByLabelText('メールアドレス')).toBeInTheDocument()
    expect(screen.getByLabelText('パスワード')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'ログイン' })).toBeInTheDocument()
  })

  it('メールアドレスとパスワードを入力できる', async () => {
    const user = userEvent.setup()
    
    render(
      <AuthProvider>
        <Login />
      </AuthProvider>
    )

    const emailInput = screen.getByLabelText('メールアドレス')
    const passwordInput = screen.getByLabelText('パスワード')

    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')

    expect(emailInput).toHaveValue('test@example.com')
    expect(passwordInput).toHaveValue('password123')
  })

  it('パスワード表示/非表示トグルが動作する', async () => {
    const user = userEvent.setup()
    
    render(
      <AuthProvider>
        <Login />
      </AuthProvider>
    )

    const passwordInput = screen.getByLabelText('パスワード')
    const toggleButton = screen.getByRole('button', { name: /パスワード.*表示/ })

    // 初期状態ではpassword type
    expect(passwordInput).toHaveAttribute('type', 'password')

    // トグルボタンをクリック
    await user.click(toggleButton)
    expect(passwordInput).toHaveAttribute('type', 'text')

    // もう一度クリック
    await user.click(toggleButton)
    expect(passwordInput).toHaveAttribute('type', 'password')
  })

  it('ログイン成功時にlogin関数が呼ばれる', async () => {
    const user = userEvent.setup()
    const mockLoginApi = vi.fn().mockResolvedValue({
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      created_at: '',
      updated_at: ''
    })
    
    vi.mocked(authApi.login).mockImplementation(mockLoginApi)

    render(
      <AuthProvider>
        <Login />
      </AuthProvider>
    )

    // フォームに入力
    await user.type(screen.getByLabelText('メールアドレス'), 'test@example.com')
    await user.type(screen.getByLabelText('パスワード'), 'password123')

    // ログインボタンをクリック
    await user.click(screen.getByRole('button', { name: 'ログイン' }))

    await waitFor(() => {
      expect(mockLoginApi).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123'
      })
      expect(mockLogin).toHaveBeenCalledWith({
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        created_at: '',
        updated_at: ''
      })
    })
  })

  it('ログイン失敗時にエラーメッセージが表示される', async () => {
    const user = userEvent.setup()
    const mockLoginApi = vi.fn().mockRejectedValue(new Error('ログインに失敗しました'))
    
    vi.mocked(authApi.login).mockImplementation(mockLoginApi)

    render(
      <AuthProvider>
        <Login />
      </AuthProvider>
    )

    // フォームに入力
    await user.type(screen.getByLabelText('メールアドレス'), 'test@example.com')
    await user.type(screen.getByLabelText('パスワード'), 'wrongpassword')

    // ログインボタンをクリック
    await user.click(screen.getByRole('button', { name: 'ログイン' }))

    await waitFor(() => {
      expect(screen.getByText('ログインに失敗しました')).toBeInTheDocument()
    })
  })

  it('ローディング中はボタンが無効化される', async () => {
    const user = userEvent.setup()
    const mockLoginApi = vi.fn().mockImplementation(() => new Promise(resolve => setTimeout(resolve, 1000)))
    
    vi.mocked(authApi.login).mockImplementation(mockLoginApi)

    render(
      <AuthProvider>
        <Login />
      </AuthProvider>
    )

    // フォームに入力
    await user.type(screen.getByLabelText('メールアドレス'), 'test@example.com')
    await user.type(screen.getByLabelText('パスワード'), 'password123')

    // ログインボタンをクリック
    await user.click(screen.getByRole('button', { name: 'ログイン' }))

    // ローディング中のボタンが表示される
    expect(screen.getByRole('button', { name: 'ログイン中...' })).toBeDisabled()
  })

  it('新規登録リンクがクリックできる', async () => {
    const user = userEvent.setup()
    const mockOnSwitchToSignup = vi.fn()

    render(
      <AuthProvider>
        <Login onSwitchToSignup={mockOnSwitchToSignup} />
      </AuthProvider>
    )

    const signupLink = screen.getByRole('button', { name: '新規登録はこちら' })
    await user.click(signupLink)

    expect(mockOnSwitchToSignup).toHaveBeenCalled()
  })

  it('必須フィールドが空の場合は送信されない', async () => {
    const user = userEvent.setup()
    const mockLoginApi = vi.fn()
    
    vi.mocked(authApi.login).mockImplementation(mockLoginApi)

    render(
      <AuthProvider>
        <Login />
      </AuthProvider>
    )

    // 空のフォームでログインボタンをクリック
    await user.click(screen.getByRole('button', { name: 'ログイン' }))

    // API呼び出しがされないことを確認
    expect(mockLoginApi).not.toHaveBeenCalled()
  })
})