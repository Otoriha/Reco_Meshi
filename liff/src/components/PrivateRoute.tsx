import React, { useEffect } from 'react'
import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const PrivateRoute: React.FC = () => {
  const { isInitialized, isAuthenticated, isInClient, login } = useAuth()

  if (!isInitialized) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="bg-white p-8 rounded-lg shadow-md">
          <h1 className="text-xl font-bold text-gray-800 mb-2">初期化中...</h1>
        </div>
      </div>
    )
  }

  if (!isInClient) {
    const liffId = import.meta.env.VITE_LIFF_ID
    const deepLink = `line://app/${liffId}`
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="bg-white p-8 rounded-lg shadow-md text-center">
          <h1 className="text-xl font-bold text-gray-800 mb-4">LINEで開いてください</h1>
          <p className="text-gray-600 mb-6">このページはLINEアプリ内での表示が必要です。</p>
          <a href={deepLink} className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700">LINEで開く</a>
        </div>
      </div>
    )
  }

  useEffect(() => {
    if (!isAuthenticated && isInitialized && isInClient) {
      login()
    }
  }, [isAuthenticated, isInitialized, isInClient, login])

  if (!isAuthenticated) return <Navigate to="/" replace />

  return <Outlet />
}

export default PrivateRoute
