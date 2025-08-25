import axios from 'axios'
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

apiClient.interceptors.request.use(async (config) => {
  if (!config.headers) config.headers = {} as any
  if (accessToken) {
    config.headers['Authorization'] = `Bearer ${accessToken}`
  }
  return config
})

apiClient.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config
    const alreadyRetried = original && (original as any).__isRetry
    if (!original || alreadyRetried) {
      return Promise.reject(error)
    }

    // 401時にIDトークンからJWTを再取得して1度だけリトライ
    if (error.response?.status === 401) {
      try {
        const idToken = liff.getIDToken()
        if (!idToken) throw new Error('IDトークンなし')
        interface LineAuthResponse {
          token: string
          user?: { 
            userId?: string; displayName?: string; pictureUrl?: string
            id?: string | number; name?: string; picture?: string
          }
        }
        let data: LineAuthResponse
        try {
          // nonceを生成
          const nonceResponse = await axiosPlain.post<{ nonce: string }>('/auth/generate_nonce')
          const nonce = nonceResponse.data.nonce
          
          const res = await axiosPlain.post<LineAuthResponse>('/auth/line_login', { 
            idToken: idToken,
            nonce: nonce
          })
          data = res.data
        } catch (e) {
          console.error('LINE認証API呼び出し失敗:', e)
          throw e
        }
        if (!data?.token) throw new Error('JWT未取得')
        setAccessToken(data.token)
        ;(original as any).__isRetry = true
        return apiClient.request(original)
      } catch (e) {
        // 再取得失敗時はログイン誘導
        try {
          liff.login({ redirectUri: window.location.href })
        } catch (_) {}
      }
    }
    return Promise.reject(error)
  }
)
