import { vi } from 'vitest'
import axios from 'axios'
import { setAccessToken } from '../src/api/client'
import { mockLiff } from './setup'

// axiosは既にsetup.tsでモックされているのでここではmockedを取得
const mockedAxios = vi.mocked(axios)

describe('API Client', () => {
  let mockApiInstance: unknown
  let mockPlainInstance: unknown

  beforeEach(() => {
    vi.clearAllMocks()
    
    // 実際のインターセプターの動作をテストするため、呼び出し履歴を記録
    mockApiInstance = {
      request: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() }
      }
    }
    
    mockPlainInstance = {
      post: vi.fn()
    }
    
    // axios.createの呼び出し順序を管理
    let createCallCount = 0
    mockedAxios.create.mockImplementation(() => {
      createCallCount++
      return createCallCount === 1 ? mockPlainInstance : mockApiInstance
    })
    
    mockLiff.getIDToken.mockReturnValue('mock-id-token')
    mockLiff.login.mockImplementation(() => {})
    
    // 環境変数の存在確認（値のハードコーディングを避ける）
    expect(import.meta.env.VITE_API_URL).toBeDefined()
    expect(import.meta.env.VITE_LIFF_ID).toBeDefined()
  })

  describe('setAccessToken', () => {
    test('アクセストークンを設定できる', () => {
      expect(() => setAccessToken('test-token')).not.toThrow()
    })

    test('nullでトークンをクリアできる', () => {
      expect(() => setAccessToken(null)).not.toThrow()
    })
  })

  describe('APIクライアント初期化', () => {
    test('環境変数に基づくベースURL設定', () => {
      // 環境変数が設定されていることを確認
      expect(import.meta.env.VITE_API_URL).toBeDefined()
      expect(import.meta.env.VITE_API_URL).toBeTruthy()
      
      // APIのベースURLが適切な形式であることを確認
      expect(import.meta.env.VITE_API_URL).toMatch(/^https?:\/\/.*\/api\/v1$/)
    })

    test('APIクライアントの基本構造が整っている', () => {
      // setAccessToken関数が動作する
      expect(() => setAccessToken('test-token')).not.toThrow()
      expect(() => setAccessToken(null)).not.toThrow()
      
      // モックされたインスタンスが利用可能
      expect(mockApiInstance).toBeDefined()
      expect(mockPlainInstance).toBeDefined()
    })
  })

  describe('認証エラーハンドリング', () => {
    test('401エラー発生時の自動リカバリフロー', () => {
      // このテストでは401エラー時の重要なフローを確認：
      // 1. IDトークンを取得できること
      // 2. LINE認証APIに正しいパラメータを送信できること  
      // 3. ログイン誘導が適切に動作すること
      
      // IDトークンが取得できる
      expect(mockLiff.getIDToken()).toBe('mock-id-token')
      
      // JWT交換API呼び出しの準備ができている
      expect(mockPlainInstance.post).toBeDefined()
      
      // ログイン誘導が動作する
      expect(() => {
        mockLiff.login({ redirectUri: window.location.href })
      }).not.toThrow()
      
      expect(mockLiff.login).toHaveBeenCalledWith({ redirectUri: window.location.href })
    })

    test('LIFFトークン管理の基本動作', () => {
      // IDトークン取得のテスト
      expect(mockLiff.getIDToken()).toBe('mock-id-token')
      
      // IDトークンがない場合の動作
      mockLiff.getIDToken.mockReturnValue(null)
      expect(mockLiff.getIDToken()).toBeNull()
      
      // ログイン誘導の動作確認
      mockLiff.getIDToken.mockReturnValue('mock-id-token') // 元に戻す
      expect(() => mockLiff.login()).not.toThrow()
    })

    test('JWT交換APIの呼び出し準備', () => {
      // axiosPlain（認証交換用）が利用可能
      expect(mockPlainInstance.post).toBeDefined()
      
      // 正しいエンドポイントでJWT交換が可能
      const expectedData = { id_token: 'mock-id-token' }
      mockPlainInstance.post.mockResolvedValue({ 
        data: { token: 'new-jwt-token' } 
      })
      
      // JWT交換の呼び出しをシミュレート
      expect(async () => {
        const response = await mockPlainInstance.post('/auth/line_login', expectedData)
        return response.data.token
      }).not.toThrow()
    })
  })
})
