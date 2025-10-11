import axios from 'axios'
import type { AxiosRequestConfig, InternalAxiosRequestConfig } from 'axios'
import liff from '@line/liff'

const baseURL = import.meta.env.VITE_API_URL as string | undefined
// 未設定時はフォールバックURLを使用（白画面回避）
const apiBaseURL = baseURL || `${window.location.origin}/api/v1`

if (!baseURL) {
  console.error('VITE_API_URL が設定されていません。フォールバックURL を使用:', apiBaseURL)
}

export const axiosPlain = axios.create({ baseURL: apiBaseURL })

let accessToken: string | null = null
export const setAccessToken = (token: string | null) => {
  accessToken = token
}

export const apiClient = axios.create({ baseURL: apiBaseURL })

// リトライフラグを持つ拡張型
interface RetryableAxiosRequestConfig extends AxiosRequestConfig {
  __isRetry?: boolean
}

apiClient.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  if (!config.headers) {
    // TypeScriptの型エラーを避けるため、ヘッダーを初期化
    config.headers = {} as InternalAxiosRequestConfig['headers']
  }
  if (accessToken) {
    config.headers['Authorization'] = `Bearer ${accessToken}`
  }
  return config
})

apiClient.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config as RetryableAxiosRequestConfig | undefined
    const alreadyRetried = original && original.__isRetry
    if (!original || alreadyRetried) {
      return Promise.reject(error)
    }

    // 401時にIDトークンからJWTを再取得して1度だけリトライ
    if (error.response?.status === 401) {
      try {
        const idToken = liff.getIDToken()
        if (!idToken) throw new Error('IDトークンなし')
        // サーバーでnonceを生成
        const nonceRes = await axiosPlain.post<{ nonce: string }>('/auth/generate_nonce')
        const nonce = nonceRes.data?.nonce
        if (!nonce) throw new Error('nonce未取得')
        interface LineAuthResponse { token: string }
        const res = await axiosPlain.post<LineAuthResponse>('/auth/line_login', { idToken, nonce })
        const data = res.data
        if (!data?.token) throw new Error('JWT未取得')
        setAccessToken(data.token)
        original.__isRetry = true
        return apiClient.request(original)
      } catch {
        // 再取得失敗時はログイン誘導
        try {
          liff.login({ redirectUri: window.location.href })
        } catch {
          // ログイン誘導に失敗した場合は何もしない
        }
      }
    }
    return Promise.reject(error)
  }
)
