import { vi } from 'vitest'
import { setAccessToken } from '../src/api/client'
import { mockLiff } from './setup'

describe('API Client', () => {
  let mockAxiosInstance: any
  let mockPlainInstance: any

  beforeEach(() => {
    vi.clearAllMocks()
    
    mockAxiosInstance = {
      request: vi.fn(),
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
      interceptors: {
        request: {
          use: vi.fn(),
        },
        response: {
          use: vi.fn(),
        },
      },
    }
    
    mockPlainInstance = {
      post: vi.fn(),
    }
    
    mockedAxios.create.mockImplementation((config) => {
      if (config?.baseURL === 'http://localhost:3000/api/v1') {
        return config === axiosPlain ? mockPlainInstance : mockAxiosInstance
      }
      return mockAxiosInstance
    })
    
    mockLiff.getIDToken.mockReturnValue('mock-id-token')
    mockLiff.login.mockImplementation(() => {})
  })

  describe('setAccessToken', () => {
    test('アクセストークンを設定できる', () => {
      expect(() => setAccessToken('test-token')).not.toThrow()
    })

    test('nullでトークンをクリアできる', () => {
      expect(() => setAccessToken(null)).not.toThrow()
    })
  })

  describe('apiClient interceptors', () => {
    test('リクエストインターセプターでAuthorizationヘッダーを付与', () => {
      // インターセプターの登録を確認
      expect(mockAxiosInstance.interceptors.request.use).toHaveBeenCalled()
      
      const requestInterceptor = mockAxiosInstance.interceptors.request.use.mock.calls[0][0]
      
      // アクセストークンを設定
      setAccessToken('test-jwt-token')
      
      // リクエスト設定をテスト
      const config = { headers: {} }
      const result = requestInterceptor(config)
      
      expect(result.headers['Authorization']).toBe('Bearer test-jwt-token')
    })

    test('アクセストークンがない場合はヘッダーを付与しない', () => {
      const requestInterceptor = mockAxiosInstance.interceptors.request.use.mock.calls[0][0]
      
      setAccessToken(null)
      
      const config = { headers: {} }
      const result = requestInterceptor(config)
      
      expect(result.headers['Authorization']).toBeUndefined()
    })

    test('ヘッダーがない場合は初期化する', () => {
      const requestInterceptor = mockAxiosInstance.interceptors.request.use.mock.calls[0][0]
      
      setAccessToken('test-token')
      
      const config = {}
      const result = requestInterceptor(config)
      
      expect(result.headers).toBeDefined()
      expect(result.headers['Authorization']).toBe('Bearer test-token')
    })
  })

  describe('401エラー時の自動リトライ', () => {
    test('401エラー時にIDトークンからJWTを再取得してリトライ', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      
      // 401エラーをモック
      const error = {
        response: { status: 401 },
        config: { url: '/test', method: 'get' }
      }
      
      // JWT交換APIの成功レスポンス
      mockPlainInstance.post.mockResolvedValue({
        data: { token: 'new-jwt-token' }
      })
      
      // リトライ時のレスポンス
      mockAxiosInstance.request.mockResolvedValue({ data: 'success' })
      
      const result = await responseInterceptor(error)
      
      // IDトークンを使ってJWT再取得
      expect(mockPlainInstance.post).toHaveBeenCalledWith('/auth/line_login', {
        id_token: 'mock-id-token'
      })
      
      // リトライマークが付与される
      expect(error.config.__isRetry).toBe(true)
      
      // 元のリクエストがリトライされる
      expect(mockAxiosInstance.request).toHaveBeenCalledWith(error.config)
      
      expect(result).toEqual({ data: 'success' })
    })

    test('IDトークンがない場合はログイン誘導', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      
      mockLiff.getIDToken.mockReturnValue(null)
      
      const error = {
        response: { status: 401 },
        config: { url: '/test' }
      }
      
      await expect(responseInterceptor(error)).rejects.toEqual(error)
      
      expect(mockLiff.login).toHaveBeenCalledWith({
        redirectUri: 'http://localhost:3002/'
      })
    })

    test('JWT再取得失敗時はログイン誘導', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      
      const error = {
        response: { status: 401 },
        config: { url: '/test' }
      }
      
      // JWT交換APIが失敗
      mockPlainInstance.post.mockRejectedValue(new Error('JWT exchange failed'))
      
      await expect(responseInterceptor(error)).rejects.toEqual(error)
      
      expect(mockLiff.login).toHaveBeenCalledWith({
        redirectUri: 'http://localhost:3002/'
      })
    })

    test('既にリトライ済みの場合は再リトライしない', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      
      const error = {
        response: { status: 401 },
        config: { url: '/test', __isRetry: true }
      }
      
      await expect(responseInterceptor(error)).rejects.toEqual(error)
      
      // JWT再取得は実行されない
      expect(mockPlainInstance.post).not.toHaveBeenCalled()
    })

    test('401以外のエラーはそのまま通す', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      
      const error = {
        response: { status: 500 },
        config: { url: '/test' }
      }
      
      await expect(responseInterceptor(error)).rejects.toEqual(error)
      
      expect(mockPlainInstance.post).not.toHaveBeenCalled()
      expect(mockLiff.login).not.toHaveBeenCalled()
    })

    test('configがない場合はそのまま通す', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      
      const error = {
        response: { status: 401 }
      }
      
      await expect(responseInterceptor(error)).rejects.toEqual(error)
      
      expect(mockPlainInstance.post).not.toHaveBeenCalled()
    })

    test('JWT再取得時にエラーログを出力', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
      
      const error = {
        response: { status: 401 },
        config: { url: '/test' }
      }
      
      const authError = new Error('Auth API failed')
      mockPlainInstance.post.mockRejectedValue(authError)
      
      await expect(responseInterceptor(error)).rejects.toEqual(error)
      
      expect(consoleSpy).toHaveBeenCalledWith('LINE認証API呼び出し失敗:', authError)
    })
  })

  describe('レスポンスインターセプター', () => {
    test('正常レスポンスはそのまま通す', () => {
      const successInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][0]
      const response = { data: 'success', status: 200 }
      
      expect(successInterceptor(response)).toEqual(response)
    })
  })
})