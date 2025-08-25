import axios from 'axios'
import liff from '@line/liff'

const baseURL = import.meta.env.VITE_API_URL as string | undefined
if (!baseURL) {
  // 実行時にUndefinedだと以降の通信が全て失敗するため、明示的にエラー化
  // ただしビルド時型はstring | undefinedのまま
  // eslint-disable-next-line no-throw-literal
  throw new Error('VITE_API_URL が設定されていません')
}

export const axiosPlain = axios.create({ baseURL })

let accessToken: string | null = null
export const setAccessToken = (token: string | null) => {
  accessToken = token
}

export const apiClient = axios.create({ baseURL })

apiClient.interceptors.request.use(async (config) => {
  if (!config.headers) config.headers = {}
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
        const { data } = await axiosPlain.post('/auth/line_login', { id_token: idToken })
        if (data?.token) {
          setAccessToken(data.token as string)
          ;(original as any).__isRetry = true
          return apiClient(original)
        }
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
