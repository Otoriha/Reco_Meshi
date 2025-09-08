import React from 'react'
import { renderHook, waitFor } from '@testing-library/react'
import { vi } from 'vitest'
import axios from 'axios'
import { useAuth } from '../src/hooks/useAuth'
import { AuthProvider } from '../src/contexts/AuthContext'
import { mockLiff } from './setup'
const mockedAxios = vi.mocked(axios)

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <AuthProvider>{children}</AuthProvider>
)

describe('useAuth', () => {
  beforeEach(async () => {
    // 呼び出し履歴のみクリア（setup.tsのグローバルモックは保持）
    vi.clearAllMocks()

    mockLiff.isInClient.mockReturnValue(true)
    mockLiff.isLoggedIn.mockReturnValue(true)
    // IDトークン・デコード済みトークンの形を明示（有効期限は将来時刻）
    const futureExp = Math.floor(Date.now() / 1000) + 3600
    mockLiff.getIDToken.mockReturnValue('mock-id-token')
    mockLiff.getDecodedIDToken.mockReturnValue({ exp: futureExp } as any)

    // axiosPlain.post をURLに応じて分岐モック
    const { axiosPlain } = await import('../src/api/client')
    if ('mockRestore' in axiosPlain.post) {
      // @ts-ignore
      axiosPlain.post.mockRestore()
    }
    vi.spyOn(axiosPlain, 'post').mockImplementation((url: string) => {
      if (typeof url === 'string' && url.includes('/auth/generate_nonce')) {
        return Promise.resolve({ data: { nonce: 'mock-nonce' } } as any)
      }
      if (typeof url === 'string' && url.includes('/auth/line_login')) {
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
      }
      return Promise.resolve({ data: {} } as any)
    })

    // 直接axios.createを呼ぶ箇所があっても成功するよう一応モック
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

  test('AuthProviderなしで使用するとエラー', () => {
    expect(() => {
      renderHook(() => useAuth())
    }).toThrow('useAuth must be used within AuthProvider')
  })

  test('AuthProvider内で使用すると認証情報を取得', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper })
    
    // 初期状態は未初期化
    expect(result.current.isInitialized).toBe(false)
    expect(result.current.isAuthenticated).toBe(false)
    
    // 初期化完了まで待機
    await waitFor(() => {
      expect(result.current.isInitialized).toBe(true)
    })
    
    // 認証完了まで待機
    await waitFor(() => {
      expect(result.current.isAuthenticated).toBe(true)
    })
    
    expect(result.current.isInClient).toBe(true)
    expect(result.current.user).toEqual({
      userId: 'mock-user-id',
      displayName: 'Mock User',
      pictureUrl: 'https://example.com/avatar.jpg'
    })
    
    expect(typeof result.current.login).toBe('function')
    expect(typeof result.current.logout).toBe('function')
  })

  test('ログイン関数が正常に動作', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper })
    
    await waitFor(() => {
      expect(result.current.isInitialized).toBe(true)
    })
    
    // ログアウト状態に変更
    mockLiff.isLoggedIn.mockReturnValue(false)
    
    // ログイン実行
    await result.current.login()
    
    expect(mockLiff.login).toHaveBeenCalledWith({ redirectUri: 'http://localhost:3002/' })
  })

  test('ログアウト関数が正常に動作', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper })
    
    await waitFor(() => {
      expect(result.current.isAuthenticated).toBe(true)
    })
    
    // ログアウト実行（状態更新をactで包む）
    await import('react').then(async ({ act }) => {
      await act(async () => {
        result.current.logout()
      })
    })
    
    expect(mockLiff.logout).toHaveBeenCalled()
    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBe(null)
  })

  test('LIFF外アクセス時の状態', async () => {
    mockLiff.isInClient.mockReturnValue(false)
    
    const { result } = renderHook(() => useAuth(), { wrapper })
    
    await waitFor(() => {
      expect(result.current.isInitialized).toBe(true)
    })
    
    expect(result.current.isInClient).toBe(false)
    expect(result.current.isAuthenticated).toBe(false)
  })

  test('未ログイン時の状態', async () => {
    mockLiff.isLoggedIn.mockReturnValue(false)
    
    const { result } = renderHook(() => useAuth(), { wrapper })
    
    await waitFor(() => {
      expect(result.current.isInitialized).toBe(true)
    })
    
    expect(result.current.isInClient).toBe(true)
    expect(result.current.isAuthenticated).toBe(false)
  })

  test('JWT交換失敗時の状態', async () => {
    // axiosPlain.post を直接モックして失敗させる
    const { axiosPlain } = await import('../src/api/client')
    vi.spyOn(axiosPlain, 'post').mockRejectedValue(new Error('JWT exchange failed'))

    const { result } = renderHook(() => useAuth(), { wrapper })
    
    await waitFor(() => {
      expect(result.current.isInitialized).toBe(true)
    })
    
    expect(result.current.isInClient).toBe(true)
    expect(result.current.isAuthenticated).toBe(false)
  })

  test('セッション復元時のユーザー情報', async () => {
    const mockUser = {
      userId: 'cached-user-id',
      displayName: 'Cached User',
      pictureUrl: 'https://example.com/cached-avatar.jpg'
    }
    
    const mockSessionStorage = vi.mocked(window.sessionStorage)
    mockSessionStorage.getItem.mockReturnValue(JSON.stringify(mockUser))
    
    const { result } = renderHook(() => useAuth(), { wrapper })
    
    // sessionStorageから復元されたユーザー情報を確認
    expect(result.current.user).toEqual(mockUser)
    
    await waitFor(() => {
      expect(result.current.isInitialized).toBe(true)
    })
  })

  test('認証状態の変更がリアクティブに反映される', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper })
    
    await waitFor(() => {
      expect(result.current.isAuthenticated).toBe(true)
    })
    
    // ログアウトを実行
    await import('react').then(async ({ act }) => {
      await act(async () => {
        result.current.logout()
      })
    })
    
    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBe(null)
  })
})
