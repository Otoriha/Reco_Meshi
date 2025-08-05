import { useEffect, useState } from 'react'
import liff from '@line/liff'

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [isInitialized, setIsInitialized] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    initializeLiff()
  }, [])

  const initializeLiff = async () => {
    try {
      const liffId = import.meta.env.VITE_LIFF_ID
      if (!liffId) {
        throw new Error('LIFF IDが設定されていません')
      }

      await liff.init({ liffId })
      setIsInitialized(true)

      if (liff.isLoggedIn()) {
        setIsLoggedIn(true)
      } else {
        liff.login()
      }
    } catch (err) {
      console.error('LIFF初期化エラー:', err)
      setError(err instanceof Error ? err.message : '初期化に失敗しました')
    }
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="bg-white p-8 rounded-lg shadow-md">
          <h1 className="text-xl font-bold text-red-600 mb-2">エラー</h1>
          <p className="text-gray-700">{error}</p>
        </div>
      </div>
    )
  }

  if (!isInitialized) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="bg-white p-8 rounded-lg shadow-md">
          <h1 className="text-xl font-bold text-gray-800 mb-2">初期化中...</h1>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-4">レコめし LIFF</h1>
        {isLoggedIn && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <p className="text-gray-700">ログイン済み</p>
          </div>
        )}
      </div>
    </div>
  )
}

export default App