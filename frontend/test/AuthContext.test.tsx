import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { AuthProvider } from '../src/contexts/AuthContext'
import { useAuth } from '../src/hooks/useAuth'

// auth.tsをモック
vi.mock('../src/api/auth', () => ({
  isAuthenticated: vi.fn(),
  logout: vi.fn(),
}))

// テスト用コンポーネント
const TestComponent = () => {
  const { isLoggedIn, user, login, logout, setAuthState } = useAuth()
  
  return (
    <div>
      <div data-testid="login-status">{isLoggedIn ? 'logged-in' : 'logged-out'}</div>
      <div data-testid="user-name">{user?.name || 'no-user'}</div>
      <button 
        data-testid="login-btn" 
        onClick={() => login({ id: 1, name: 'Test User', email: 'test@example.com', created_at: '', updated_at: '' })}
      >
        Login
      </button>
      <button data-testid="logout-btn" onClick={logout}>Logout</button>
      <button 
        data-testid="set-auth-btn" 
        onClick={() => setAuthState(true, { id: 2, name: 'Auth User', email: 'auth@example.com', created_at: '', updated_at: '' })}
      >
        Set Auth
      </button>
    </div>
  )
}

describe('AuthContext', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('初期状態ではログアウト状態である', () => {
    vi.mocked(vi.importMock('../src/api/auth')).isAuthenticated.mockReturnValue(false)

    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    expect(screen.getByTestId('login-status')).toHaveTextContent('logged-out')
    expect(screen.getByTestId('user-name')).toHaveTextContent('no-user')
  })

  it('login関数でログイン状態になる', async () => {
    vi.mocked(vi.importMock('../src/api/auth')).isAuthenticated.mockReturnValue(false)

    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    const loginBtn = screen.getByTestId('login-btn')
    loginBtn.click()

    await waitFor(() => {
      expect(screen.getByTestId('login-status')).toHaveTextContent('logged-in')
      expect(screen.getByTestId('user-name')).toHaveTextContent('Test User')
    })
  })

  it('logout関数でログアウト状態になる', async () => {
    const mockLogout = vi.fn().mockResolvedValue(undefined)
    vi.mocked(vi.importMock('../src/api/auth')).logout.mockImplementation(mockLogout)
    vi.mocked(vi.importMock('../src/api/auth')).isAuthenticated.mockReturnValue(false)

    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    // まずログインする
    const loginBtn = screen.getByTestId('login-btn')
    loginBtn.click()

    await waitFor(() => {
      expect(screen.getByTestId('login-status')).toHaveTextContent('logged-in')
    })

    // ログアウトする
    const logoutBtn = screen.getByTestId('logout-btn')
    logoutBtn.click()

    await waitFor(() => {
      expect(screen.getByTestId('login-status')).toHaveTextContent('logged-out')
      expect(screen.getByTestId('user-name')).toHaveTextContent('no-user')
    })

    expect(mockLogout).toHaveBeenCalled()
  })

  it('setAuthState関数で認証状態を設定できる', async () => {
    vi.mocked(vi.importMock('../src/api/auth')).isAuthenticated.mockReturnValue(false)

    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    const setAuthBtn = screen.getByTestId('set-auth-btn')
    setAuthBtn.click()

    await waitFor(() => {
      expect(screen.getByTestId('login-status')).toHaveTextContent('logged-in')
      expect(screen.getByTestId('user-name')).toHaveTextContent('Auth User')
    })
  })
})