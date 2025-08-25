import React from 'react'
import { render, screen, waitFor, act } from '@testing-library/react'
import { AuthProvider, AuthContext, LiffUser } from '../src/contexts/AuthContext'
import { mockLiff } from './setup'
import axios from 'axios'

// axiosをモック
vi.mock('axios')
const mockedAxios = vi.mocked(axios)

// テスト用のコンポーネント
const TestComponent = () => {
  const auth = React.useContext(AuthContext)
  if (!auth) return <div>No Auth Context</div>
  
  const { isInitialized, isAuthenticated, isInClient, user, login, logout } = auth
  
  return (
    <div>
      <div data-testid="initialized">{isInitialized ? 'true' : 'false'}</div>
      <div data-testid="authenticated">{isAuthenticated ? 'true' : 'false'}</div>
      <div data-testid="in-client">{isInClient ? 'true' : 'false'}</div>
      <div data-testid="user">{user ? user.displayName : 'null'}</div>
      <button data-testid="login" onClick={login}>Login</button>
      <button data-testid="logout" onClick={logout}>Logout</button>
    </div>
  )
}

const renderWithProvider = (children: React.ReactNode) => {
  return render(
    <AuthProvider>
      {children}
    </AuthProvider>
  )
}

describe('AuthContext', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // sessionStorageをクリア
    const mockSessionStorage = vi.mocked(window.sessionStorage)
    mockSessionStorage.clear()
    mockSessionStorage.getItem.mockReturnValue(null)
    
    // axiosのデフォルトモック設定
    mockedAxios.create.mockReturnValue({
      post: vi.fn().mockResolvedValue({
        data: {
          token: 'mock-jwt-token',
          user: {
            userId: 'mock-user-id',
            displayName: 'Mock User',
            pictureUrl: 'https://example.com/avatar.jpg'
          }
        }
      })
    } as any)
  })

  test('正常初期化後、認証済みユーザーが表示される', async () => {
    renderWithProvider(<TestComponent />)
    
    // 初期化中の表示確認
    expect(screen.getByTestId('initialized')).toHaveTextContent('false')
    
    // 初期化完了後の確認
    await waitFor(() => {
      expect(screen.getByTestId('initialized')).toHaveTextContent('true')
    })
    
    await waitFor(() => {
      expect(screen.getByTestId('authenticated')).toHaveTextContent('true')
    })
    
    expect(screen.getByTestId('in-client')).toHaveTextContent('true')
    expect(screen.getByTestId('user')).toHaveTextContent('Mock User')
  })

  test('LIFF外アクセス時は認証されない', async () => {
    mockLiff.isInClient.mockReturnValue(false)
    
    renderWithProvider(<TestComponent />)
    
    await waitFor(() => {
      expect(screen.getByTestId('initialized')).toHaveTextContent('true')
    })
    
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
    expect(screen.getByTestId('in-client')).toHaveTextContent('false')
  })

  test('LIFFログイン未完了時は認証されない', async () => {
    mockLiff.isLoggedIn.mockReturnValue(false)
    
    renderWithProvider(<TestComponent />)
    
    await waitFor(() => {
      expect(screen.getByTestId('initialized')).toHaveTextContent('true')
    })
    
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
    expect(screen.getByTestId('in-client')).toHaveTextContent('true')
  })

  test('JWT交換失敗時は認証されない', async () => {
    const mockAxiosInstance = {
      post: vi.fn().mockRejectedValue(new Error('JWT exchange failed'))
    }
    mockedAxios.create.mockReturnValue(mockAxiosInstance as any)
    
    renderWithProvider(<TestComponent />)
    
    await waitFor(() => {
      expect(screen.getByTestId('initialized')).toHaveTextContent('true')
    })
    
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
  })

  test('sessionStorageからユーザー情報を復元', async () => {
    const mockUser: LiffUser = {
      userId: 'cached-user-id',
      displayName: 'Cached User',
      pictureUrl: 'https://example.com/cached-avatar.jpg'
    }
    
    const mockSessionStorage = vi.mocked(window.sessionStorage)
    mockSessionStorage.getItem.mockReturnValue(JSON.stringify(mockUser))
    
    renderWithProvider(<TestComponent />)
    
    // sessionStorageからの復元確認
    expect(screen.getByTestId('user')).toHaveTextContent('Cached User')
  })

  test('ログアウト処理が正常に動作する', async () => {
    renderWithProvider(<TestComponent />)
    
    // 初期化完了まで待機
    await waitFor(() => {
      expect(screen.getByTestId('authenticated')).toHaveTextContent('true')
    })
    
    // ログアウト実行
    await act(async () => {
      screen.getByTestId('logout').click()
    })
    
    expect(mockLiff.logout).toHaveBeenCalled()
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
    expect(screen.getByTestId('user')).toHaveTextContent('null')
  })

  test('環境変数未設定時はエラー', async () => {
    // VITE_LIFF_IDを削除
    vi.stubEnv('VITE_LIFF_ID', undefined as any)
    
    renderWithProvider(<TestComponent />)
    
    await waitFor(() => {
      expect(screen.getByTestId('initialized')).toHaveTextContent('true')
    })
    
    // 認証が失敗していることを確認
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
  })
})