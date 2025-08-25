import React, { createContext, useCallback, useEffect, useMemo, useState } from 'react'
import liff from '@line/liff'
import { axiosPlain, setAccessToken } from '../api/client'

export type LiffUser = {
  userId: string
  displayName: string
  pictureUrl?: string
}

type AuthContextType = {
  isInitialized: boolean
  isAuthenticated: boolean
  isInClient: boolean
  user: LiffUser | null
  login: () => Promise<void>
  logout: () => void
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined)

const SESSION_USER_KEY = 'liff_user'

interface LineAuthResponse {
  token: string
  user?: {
    userId: string
    displayName: string
    pictureUrl?: string
  }
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isInitialized, setIsInitialized] = useState(false)
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [isInClient, setIsInClient] = useState(false)
  const [user, setUser] = useState<LiffUser | null>(() => {
    try {
      const raw = sessionStorage.getItem(SESSION_USER_KEY)
      return raw ? (JSON.parse(raw) as LiffUser) : null
    } catch {
      return null
    }
  })

  const liffId = import.meta.env.VITE_LIFF_ID as string | undefined
  const apiUrl = import.meta.env.VITE_API_URL as string | undefined

  const persistUser = (u: LiffUser | null) => {
    if (!u) {
      sessionStorage.removeItem(SESSION_USER_KEY)
    } else {
      sessionStorage.setItem(SESSION_USER_KEY, JSON.stringify(u))
    }
  }

  const exchangeJwt = useCallback(async (): Promise<boolean> => {
    try {
      // IDトークンの有効期限をチェック
      const decodedToken = liff.getDecodedIDToken()
      const currentTime = Math.floor(Date.now() / 1000)
      
      console.log('IDトークン詳細:', {
        aud: decodedToken?.aud,
        iss: decodedToken?.iss,
        exp: decodedToken?.exp,
        nonce: decodedToken?.nonce,
        currentTime: currentTime,
        expired: decodedToken?.exp ? decodedToken.exp < currentTime : 'exp不明'
      })
      
      // IDトークンが期限切れの場合は再ログイン
      if (decodedToken?.exp && decodedToken.exp < currentTime) {
        console.log('IDトークンが期限切れです。再ログインします。')
        liff.login({ redirectUri: window.location.href })
        return false
      }
      
      const idToken = liff.getIDToken()
      console.log('IDトークン取得:', idToken ? 'あり' : 'なし')
      if (!idToken) return false
      
      // nonceを生成
      console.log('nonce生成中...')
      const nonceResponse = await axiosPlain.post<{ nonce: string }>('/auth/generate_nonce')
      const nonce = nonceResponse.data.nonce
      console.log('nonce生成完了:', nonce)
      
      console.log('JWT交換開始...')
      const { data } = await axiosPlain.post<LineAuthResponse>('/auth/line_login', { 
        idToken: idToken,
        nonce: nonce
      })
      console.log('JWT交換レスポンス:', data)
      if (data?.token) {
        console.log('JWT取得成功、認証状態を更新')
        setAccessToken(data.token)
        // 優先度: サーバーが返すユーザー > LIFFプロフィール
        if (data.user?.userId && data.user?.displayName) {
          const u: LiffUser = {
            userId: data.user.userId,
            displayName: data.user.displayName,
            pictureUrl: data.user.pictureUrl,
          }
          console.log('ユーザー情報設定（サーバー）:', u)
          setUser(u)
          persistUser(u)
        } else {
          // フォールバック: LIFFプロフィールから取得
          const profile = await liff.getProfile()
          const u: LiffUser = {
            userId: profile.userId,
            displayName: profile.displayName,
            pictureUrl: profile.pictureUrl,
          }
          console.log('ユーザー情報設定（LIFF）:', u)
          setUser(u)
          persistUser(u)
        }
        console.log('JWT交換成功、認証完了')
        return true
      }
      return false
    } catch (e) {
      console.error('JWT交換に失敗しました', e)
      return false
    }
  }, [])

  const initialize = useCallback(async () => {
    try {
      if (!liffId) {
        console.error('VITE_LIFF_ID が設定されていません')
        setIsInitialized(true)
        return
      }
      if (!apiUrl) {
        console.error('VITE_API_URL が設定されていません')
        setIsInitialized(true)
        return
      }

      await liff.init({ liffId })
      setIsInClient(liff.isInClient())

      if (!liff.isInClient()) {
        // ブラウザ直アクセス時はここで終了（案内はPrivateRoute側で対応）
        setIsAuthenticated(false)
        setIsInitialized(true)
        return
      }

      if (!liff.isLoggedIn()) {
        setIsAuthenticated(false)
        setIsInitialized(true)
        return
      }

      // ログイン済みならバックエンドJWTを取得
      const ok = await exchangeJwt()
      setIsAuthenticated(ok)
    } catch (e) {
      console.error('LIFF初期化エラー', e)
    } finally {
      setIsInitialized(true)
    }
  }, [apiUrl, exchangeJwt, liffId])

  useEffect(() => {
    initialize()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const login = useCallback(async () => {
    if (!liff.isLoggedIn()) {
      liff.login({ redirectUri: window.location.href })
      return
    }
    // IDトークンの有効期限をチェックしてJWT交換
    const ok = await exchangeJwt()
    setIsAuthenticated(ok)
  }, [exchangeJwt])

  const logout = useCallback(() => {
    try {
      liff.logout()
    } catch (_) {}
    setAccessToken(null)
    setIsAuthenticated(false)
    setUser(null)
    persistUser(null)
  }, [])

  const value = useMemo<AuthContextType>(() => ({
    isInitialized,
    isAuthenticated,
    isInClient,
    user,
    login,
    logout,
  }), [isInitialized, isAuthenticated, isInClient, user, login, logout])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
