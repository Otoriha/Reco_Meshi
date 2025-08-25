import React from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'

const Home: React.FC = () => {
  const { isInitialized, isAuthenticated, user, login, logout } = useAuth()

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-4">レコめし LIFF</h1>
        <div className="bg-white rounded-lg shadow-md p-6">
          {!isInitialized && <p className="text-gray-600">初期化中...</p>}
          {isInitialized && (
            <>
              {!import.meta.env.VITE_LIFF_ID || !import.meta.env.VITE_API_URL ? (
                <div className="space-y-4">
                  <p className="text-red-600 font-semibold">設定エラー</p>
                  <p className="text-gray-700">環境変数が正しく設定されていません。</p>
                  <div className="text-sm text-gray-500">
                    <p>VITE_LIFF_ID: {import.meta.env.VITE_LIFF_ID || '未設定'}</p>
                    <p>VITE_API_URL: {import.meta.env.VITE_API_URL || '未設定'}</p>
                    <p>Current URL: {window.location.href}</p>
                  </div>
                </div>
              ) : isAuthenticated ? (
                <div className="space-y-4">
                  <div className="flex items-center space-x-3">
                    {user?.pictureUrl && (
                      <img src={user.pictureUrl} alt="avatar" className="w-10 h-10 rounded-full" />
                    )}
                    <div>
                      <p className="text-gray-800 font-semibold">{user?.displayName}</p>
                      <p className="text-gray-500 text-sm">ログイン済み</p>
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <Link to="/ingredients" className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">食材リスト</Link>
                    <Link to="/recipe-history" className="px-4 py-2 bg-emerald-600 text-white rounded hover:bg-emerald-700">レシピ履歴</Link>
                    <Link to="/settings" className="px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-800">設定</Link>
                  </div>
                  <button onClick={logout} className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700">ログアウト</button>
                </div>
              ) : (
                <div className="space-y-4">
                  <p className="text-gray-700">続行するにはLINEでログインしてください。</p>
                  <button onClick={login} className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700">ログイン</button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}

export default Home

