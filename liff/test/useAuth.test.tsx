import React from 'react'
import { renderHook, waitFor } from '@testing-library/react'
import { useAuth } from '../src/hooks/useAuth'
import { AuthProvider } from '../src/contexts/AuthContext'
import { mockLiff } from './setup'
import axios from 'axios'

vi.mock('axios')
const mockedAxios = vi.mocked(axios)

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <AuthProvider>{children}</AuthProvider>
)

describe('useAuth', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    
    mockLiff.isInClient.mockReturnValue(true)
    mockLiff.isLoggedIn.mockReturnValue(true)
    
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
    
    // ログアウト実行
    result.current.logout()
    
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
    const mockAxiosInstance = {
      post: vi.fn().mockRejectedValue(new Error('JWT exchange failed'))
    }
    mockedAxios.create.mockReturnValue(mockAxiosInstance as any)
    
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
    const { result, rerender } = renderHook(() => useAuth(), { wrapper })
    
    await waitFor(() => {
      expect(result.current.isAuthenticated).toBe(true)
    })
    
    // ログアウトを実行
    result.current.logout()
    
    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBe(null)
  })
})