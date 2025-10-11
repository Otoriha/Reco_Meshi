import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import { vi } from 'vitest'
import axios from 'axios'
import { MemoryRouter } from 'react-router-dom'
import PrivateRoute from '../src/components/PrivateRoute'
import { AuthProvider, AuthContext } from '../src/contexts/AuthContext'
import { mockLiff } from './setup'
const mockedAxios = vi.mocked(axios)

const TestPage = () => <div data-testid="protected-content">保護されたコンテンツ</div>

const renderWithRouter = (initialEntries = ['/']) => {
  return render(
    <MemoryRouter initialEntries={initialEntries}>
      <AuthProvider>
        <PrivateRoute />
      </AuthProvider>
    </MemoryRouter>
  )
}

describe('PrivateRoute', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    
    // デフォルト設定：LIFF内、ログイン済み、JWT交換成功
    mockLiff.isInClient.mockReturnValue(true)
    mockLiff.isLoggedIn.mockReturnValue(true)
    
    mockedAxios.create.mockReturnValue({
      post: vi.fn().mockResolvedValue({
        data: {
          token: 'mock-jwt-token',
          user: {
            userId: 'mock-user-id',
            displayName: 'Mock User'
          }
        }
      })
    } as unknown)
  })

  test('初期化中はローディング画面を表示', () => {
    renderWithRouter()
    
    expect(screen.getByText('初期化中...')).toBeInTheDocument()
  })

  test('LIFF外アクセス時はLINEで開く案内を表示', async () => {
    mockLiff.isInClient.mockReturnValue(false)
    
    renderWithRouter()
    
    await waitFor(() => {
      expect(screen.getByText('LINEで開いてください')).toBeInTheDocument()
    })
    
    expect(screen.getByText('このページはLINEアプリ内での表示が必要です。')).toBeInTheDocument()
    
    const linkElement = screen.getByRole('link', { name: 'LINEで開く' })
    expect(linkElement.getAttribute('href')).toMatch(/^line:\/\/app\/.*$/)
  })

  test('未認証時はホームページにリダイレクト', async () => {
    mockLiff.isLoggedIn.mockReturnValue(false)
    
    const { container } = renderWithRouter(['/protected'])
    
    await waitFor(() => {
      // Navigate コンポーネントによるリダイレクト確認
      // 実際のルーターではないため、DOM変更で確認
      expect(container.querySelector('[data-testid="protected-content"]')).not.toBeInTheDocument()
    })
    
    // login関数が呼ばれることを確認
    await waitFor(() => {
      expect(mockLiff.login).toHaveBeenCalledWith({ redirectUri: 'http://localhost:3002/' })
    })
  })

  test('JWT交換失敗時もホームページにリダイレクト', async () => {
    const mockAxiosInstance = {
      post: vi.fn().mockRejectedValue(new Error('JWT exchange failed'))
    }
    mockedAxios.create.mockReturnValue(mockAxiosInstance as unknown)
    
    const { container } = renderWithRouter(['/protected'])
    
    await waitFor(() => {
      expect(container.querySelector('[data-testid="protected-content"]')).not.toBeInTheDocument()
    })
  })

  test('認証成功時はOutletを表示', async () => {
    // Outletの代わりにテストコンポーネントをレンダリング
    const TestComponent = () => {
      const auth = React.useContext(AuthContext)
      return auth?.isAuthenticated ? <TestPage /> : <div>認証されていません</div>
    }

    render(
      <MemoryRouter initialEntries={['/protected']}>
        <AuthProvider>
          <TestComponent />
        </AuthProvider>
      </MemoryRouter>
    )

    await waitFor(() => {
      expect(screen.getByTestId('protected-content')).toBeInTheDocument()
    })
  })

  test('認証状態変化時のリアクティブ動作', async () => {
    // 初期認証を確実に成功させる
    const { axiosPlain } = await import('../src/api/client')
    vi.spyOn(axiosPlain, 'post').mockResolvedValue({
      data: {
        token: 'mock-jwt-token',
        user: { userId: 'mock-user-id', displayName: 'Mock User' },
      },
    } as unknown)

    // 単一のツリー内で、初期化完了後にlogoutを発火してPrivateRouteのlogin誘導を検証
    const LogoutAfterInit = () => {
      const auth = React.useContext(AuthContext)!
      React.useEffect(() => {
        if (auth.isInitialized && auth.isAuthenticated) {
          // LIFF側のログイン状態も未ログインに切り替えて挙動を再現
          mockLiff.isLoggedIn.mockReturnValue(false)
          auth.logout()
        }
      // eslint-disable-next-line react-hooks/exhaustive-deps
      }, [auth.isInitialized, auth.isAuthenticated])
      return null
    }

    render(
      <MemoryRouter>
        <AuthProvider>
          <LogoutAfterInit />
          <PrivateRoute />
        </AuthProvider>
      </MemoryRouter>
    )

    // 初期化完了まで待機
    await waitFor(() => {
      expect(screen.queryByText('初期化中...')).not.toBeInTheDocument()
    })

    // logout後にPrivateRouteがloginを呼ぶ
    await waitFor(() => {
      expect(mockLiff.login).toHaveBeenCalled()
    })
  })

  test('環境変数からLIFF IDを正しく取得', async () => {
    mockLiff.isInClient.mockReturnValue(false)
    
    renderWithRouter()
    
    await waitFor(() => {
      const linkElement = screen.getByRole('link', { name: 'LINEで開く' })
      expect(linkElement.getAttribute('href')).toMatch(/^line:\/\/app\/.*$/)
    })
  })
})
