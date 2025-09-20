import { render, screen } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import ProtectedRoute from '../../src/components/ProtectedRoute'
import * as useAuthHook from '../../src/hooks/useAuth'

// useAuthをモック
vi.mock('../../src/hooks/useAuth', () => ({
  useAuth: vi.fn(),
}))

// React Routerのモック
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    Navigate: vi.fn(({ to }) => <div data-testid="navigate">{to}</div>),
  }
})

const TestComponent = () => <div data-testid="protected-content">保護されたコンテンツ</div>

describe('ProtectedRoute', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('ログイン済みの場合は子コンポーネントが表示される', () => {
    vi.mocked(useAuthHook.useAuth).mockReturnValue({
      isLoggedIn: true,
      isAuthResolved: true,
      user: null,
      login: vi.fn(),
      logout: vi.fn(),
      setAuthState: vi.fn(),
    })

    render(
      <BrowserRouter>
        <Routes>
          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<TestComponent />} />
          </Route>
        </Routes>
      </BrowserRouter>
    )

    expect(screen.getByTestId('protected-content')).toBeInTheDocument()
  })

  it('未ログインの場合はログインページにリダイレクトされる', () => {
    vi.mocked(useAuthHook.useAuth).mockReturnValue({
      isLoggedIn: false,
      isAuthResolved: true,
      user: null,
      login: vi.fn(),
      logout: vi.fn(),
      setAuthState: vi.fn(),
    })

    render(
      <BrowserRouter>
        <Routes>
          <Route element={<ProtectedRoute />}>
            <Route path="/ingredients" element={<TestComponent />} />
          </Route>
        </Routes>
      </BrowserRouter>
    )

    expect(screen.getByTestId('navigate')).toHaveTextContent('/login?next=%2Fingredients')
  })

  it('認証判定中はローディング表示される', () => {
    vi.mocked(useAuthHook.useAuth).mockReturnValue({
      isLoggedIn: false,
      isAuthResolved: false,
      user: null,
      login: vi.fn(),
      logout: vi.fn(),
      setAuthState: vi.fn(),
    })

    render(
      <BrowserRouter>
        <Routes>
          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<TestComponent />} />
          </Route>
        </Routes>
      </BrowserRouter>
    )

    expect(screen.getByText('認証情報を確認中...')).toBeInTheDocument()
    expect(screen.queryByTestId('protected-content')).not.toBeInTheDocument()
  })

  it('クエリパラメータも含めてnextパラメータが生成される', () => {
    vi.mocked(useAuthHook.useAuth).mockReturnValue({
      isLoggedIn: false,
      isAuthResolved: true,
      user: null,
      login: vi.fn(),
      logout: vi.fn(),
      setAuthState: vi.fn(),
    })

    // URLに検索パラメータを設定
    window.history.pushState({}, '', '/ingredients?filter=vegetables')

    render(
      <BrowserRouter>
        <Routes>
          <Route element={<ProtectedRoute />}>
            <Route path="/ingredients" element={<TestComponent />} />
          </Route>
        </Routes>
      </BrowserRouter>
    )

    expect(screen.getByTestId('navigate')).toHaveTextContent('/login?next=%2Fingredients%3Ffilter%3Dvegetables')
  })
})