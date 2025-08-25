import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AuthProvider } from '../src/contexts/AuthContext'
import PrivateRoute from '../src/components/PrivateRoute'
import Home from '../src/pages/Home/Home'
import { mockLiff } from './setup'
import { vi } from 'vitest'

// 統合テスト：実際のアプリケーションフローをテスト
describe('LIFF認証統合テスト', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    
    // デフォルト：LIFF内、ログイン済み
    mockLiff.isInClient.mockReturnValue(true)
    mockLiff.isLoggedIn.mockReturnValue(true)
    
    // sessionStorageをクリア
    const mockSessionStorage = vi.mocked(window.sessionStorage)
    mockSessionStorage.clear()
    mockSessionStorage.getItem.mockReturnValue(null)
  })

  test('正常ケース：ログイン済みユーザーがホームページを表示', async () => {
    render(
      <MemoryRouter initialEntries={['/']}>
        <AuthProvider>
          <Home />
        </AuthProvider>
      </MemoryRouter>
    )
    
    // 初期化完了まで待機
    await waitFor(
      () => {
        // ホームページのコンテンツが表示されるか確認
        expect(screen.queryByText('初期化中...')).not.toBeInTheDocument()
      },
      { timeout: 5000 }
    )
    
    // ホームページが表示される
    expect(screen.getByText('レコめし LIFF')).toBeInTheDocument()
  })

  test('LIFF外アクセス時：LINE案内画面が表示される', async () => {
    mockLiff.isInClient.mockReturnValue(false)
    
    render(
      <MemoryRouter>
        <AuthProvider>
          <PrivateRoute />
        </AuthProvider>
      </MemoryRouter>
    )
    
    await waitFor(() => {
      expect(screen.getByText('LINEで開いてください')).toBeInTheDocument()
    })
    
    expect(screen.getByText('このページはLINEアプリ内での表示が必要です。')).toBeInTheDocument()
  })

  test('未ログイン時：ログインボタンが表示される', async () => {
    mockLiff.isLoggedIn.mockReturnValue(false)
    
    render(
      <MemoryRouter>
        <AuthProvider>
          <Home />
        </AuthProvider>
      </MemoryRouter>
    )
    
    await waitFor(() => {
      expect(screen.getByText('続行するにはLINEでログインしてください。')).toBeInTheDocument()
    })
    
    expect(screen.getByRole('button', { name: 'ログイン' })).toBeInTheDocument()
  })

  test('プロテクトされたルートのアクセス制御', async () => {
    // 未認証状態でプロテクトされたページにアクセス
    mockLiff.isLoggedIn.mockReturnValue(false)
    
    render(
      <MemoryRouter>
        <AuthProvider>
          <PrivateRoute />
        </AuthProvider>
      </MemoryRouter>
    )
    
    // 初期化完了まで待機してからログイン処理が呼ばれることを確認
    await waitFor(() => {
      expect(mockLiff.login).toHaveBeenCalled()
    })
  })
})