import React from 'react'
import { render, screen, waitFor, act } from '@testing-library/react'
import { vi } from 'vitest'
import axios from 'axios'
import { AuthProvider, AuthContext, LiffUser } from '../src/contexts/AuthContext'
import { mockLiff } from './setup'
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
  beforeEach(async () => {
    // 呼び出し履歴のみクリア（setup.tsのグローバルモックは保持）
    vi.clearAllMocks()
    // sessionStorageをクリア
    const mockSessionStorage = vi.mocked(window.sessionStorage)
    mockSessionStorage.clear()
    mockSessionStorage.getItem.mockReturnValue(null)
    // LIFFのデフォルト状態を復元
    mockLiff.isInClient.mockReturnValue(true)
    mockLiff.isLoggedIn.mockReturnValue(true)
    const futureExp = Math.floor(Date.now() / 1000) + 3600
    mockLiff.getIDToken.mockReturnValue('mock-id-token')
    mockLiff.getDecodedIDToken.mockReturnValue({ exp: futureExp } as any)

    // axiosPlain.post をURLで分岐するようにモック
    const { axiosPlain } = await import('../src/api/client')
    if ('mockRestore' in axiosPlain.post) {
      // @ts-ignore
      axiosPlain.post.mockRestore()
    }
    vi.spyOn(axiosPlain, 'post').mockImplementation((url: string) => {
      if (typeof url === 'string' && url.includes('/auth/generate_nonce')) {
        return Promise.resolve({ data: { nonce: 'mock-nonce' } } as any)
      }
      return Promise.resolve({
        data: {
          token: 'mock-jwt-token',
          user: {
            userId: 'mock-user-id',
            displayName: 'Mock User',
            pictureUrl: 'https://example.com/avatar.jpg',
          },
        },
      } as any)
    })

    // 念のため、axios.createベースの呼び出しにも成功レスポンスを用意
    mockedAxios.create.mockReturnValue({
      post: vi.fn().mockImplementation((url: string) => {
        if (url.includes('/auth/generate_nonce')) {
          return Promise.resolve({ data: { nonce: 'mock-nonce' } })
        }
        return Promise.resolve({
          data: {
            token: 'mock-jwt-token',
            user: {
              userId: 'mock-user-id',
              displayName: 'Mock User',
              pictureUrl: 'https://example.com/avatar.jpg',
            },
          },
        })
      }),
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
    // 既存のaxiosインスタンスに対して直接postを失敗させる
    const { axiosPlain } = await import('../src/api/client')
    vi.spyOn(axiosPlain, 'post').mockRejectedValue(new Error('JWT exchange failed'))

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
    // 初期認証を確実に成功させる（URLに応じて分岐モック）
    const { axiosPlain } = await import('../src/api/client')
    vi.spyOn(axiosPlain, 'post').mockImplementation((url: string) => {
      if (typeof url === 'string' && url.includes('/auth/generate_nonce')) {
        return Promise.resolve({ data: { nonce: 'mock-nonce' } } as any)
      }
      return Promise.resolve({
        data: {
          token: 'mock-jwt-token',
          user: { userId: 'mock-user-id', displayName: 'Mock User' },
        },
      } as any)
    })

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
