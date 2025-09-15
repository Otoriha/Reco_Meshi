import React, { useEffect, useState, useRef, useCallback } from 'react'
import { Link } from 'react-router-dom'
import type { ShoppingListSummary } from '../../types/shoppingList'
import { getShoppingLists, getShoppingListErrorMessage } from '../../api/shoppingLists'

const POLLING_INTERVAL = 30000 // 30秒

const ShoppingLists: React.FC = () => {
  const [shoppingLists, setShoppingLists] = useState<ShoppingListSummary[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isPolling, setIsPolling] = useState(false)
  const pollingTimerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const isMountedRef = useRef(true)

  const fetchShoppingLists = useCallback(async (showLoading = true) => {
    // ポーリング中の重複リクエストを防ぐ
    if (isPolling && !showLoading) return

    if (showLoading) {
      setLoading(true)
    }
    setError(null)
    setIsPolling(true)

    try {
      // 未完了・進行中のリストを取得（並列実行）
      const [pendingLists, inProgressLists] = await Promise.all([
        getShoppingLists({ status: 'pending', per_page: 50 }),
        getShoppingLists({ status: 'in_progress', per_page: 50 })
      ])
      
      // 結果をマージして作成日時でソート
      const mergedLists = [...pendingLists, ...inProgressLists].sort((a, b) => 
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      )
      
      if (isMountedRef.current) {
        setShoppingLists(mergedLists)
      }
    } catch (e) {
      console.error('買い物リスト取得エラー:', e)
      if (isMountedRef.current) {
        setError(getShoppingListErrorMessage(e))
      }
    } finally {
      if (isMountedRef.current) {
        setLoading(false)
        setIsPolling(false)
      }
    }
  }, [isPolling])

  // ポーリングの設定
  const startPolling = useCallback(() => {
    // 既存のタイマーをクリア
    if (pollingTimerRef.current) {
      clearInterval(pollingTimerRef.current)
    }

    // 新しいポーリングタイマーを設定
    pollingTimerRef.current = setInterval(() => {
      fetchShoppingLists(false) // ローディング表示なしで取得
    }, POLLING_INTERVAL)
  }, [fetchShoppingLists])

  const stopPolling = useCallback(() => {
    if (pollingTimerRef.current) {
      clearInterval(pollingTimerRef.current)
      pollingTimerRef.current = null
    }
  }, [])

  useEffect(() => {
    isMountedRef.current = true
    fetchShoppingLists()
    startPolling()

    // クリーンアップ
    return () => {
      isMountedRef.current = false
      stopPolling()
    }
  }, [])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'bg-gray-100 text-gray-800'
      case 'in_progress':
        return 'bg-blue-100 text-blue-800'
      case 'completed':
        return 'bg-green-100 text-green-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getProgressBarColor = (percentage: number) => {
    if (percentage === 0) return 'bg-gray-300'
    if (percentage < 50) return 'bg-red-400'
    if (percentage < 100) return 'bg-yellow-400'
    return 'bg-green-400'
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('ja-JP', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const handleRefresh = () => {
    fetchShoppingLists()
    // ポーリングタイマーをリセット
    startPolling()
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-4 py-8 max-w-6xl">
        <div className="mb-6 flex justify-between items-center">
          <h1 className="text-3xl font-bold text-gray-800">買い物リスト</h1>
          <button
            onClick={handleRefresh}
            disabled={loading || isPolling}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 transition-colors flex items-center gap-2"
            aria-label="リストを更新"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            更新
          </button>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          {loading && (
            <div className="text-center py-12">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <p className="text-gray-600 mt-4">読み込み中...</p>
            </div>
          )}

          {!loading && error && (
            <div className="mb-4 p-4 rounded-lg bg-red-50 text-red-700 border border-red-200">
              <div className="flex items-center gap-2">
                <svg className="w-5 h-5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
                <span>{error}</span>
              </div>
              <button
                onClick={handleRefresh}
                className="mt-2 text-red-800 underline hover:no-underline"
              >
                再試行
              </button>
            </div>
          )}

          {!loading && !error && shoppingLists.length === 0 && (
            <div className="text-center py-12">
              <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              <p className="text-gray-600 mt-4 text-lg">買い物リストがありません</p>
              <p className="text-sm text-gray-500 mt-2">
                レシピから買い物リストを作成してみましょう
              </p>
              <Link
                to="/recipes"
                className="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                レシピを見る
              </Link>
            </div>
          )}

          {!loading && !error && shoppingLists.length > 0 && (
            <div className="space-y-4">
              {shoppingLists.map((list) => (
                <Link
                  key={list.id}
                  to={`/shopping-lists/${list.id}`}
                  className="block border border-gray-200 rounded-lg p-5 hover:bg-gray-50 hover:border-gray-300 transition-all hover:shadow-md"
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <h3 className="font-semibold text-lg text-gray-900 mb-1">
                        {list.displayTitle}
                      </h3>
                      {list.recipe && (
                        <p className="text-sm text-gray-600">
                          <span className="inline-flex items-center gap-1">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                            </svg>
                            レシピ: {list.recipe.title}
                          </span>
                        </p>
                      )}
                    </div>
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(
                        list.status
                      )}`}
                    >
                      {list.statusDisplay}
                    </span>
                  </div>

                  <div className="mb-3">
                    <div className="flex items-center justify-between text-sm text-gray-600 mb-1">
                      <span>進捗: {list.totalItemsCount - list.uncheckedItemsCount} / {list.totalItemsCount} 項目</span>
                      <span className="font-medium">{list.completionPercentage}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2.5">
                      <div
                        className={`h-2.5 rounded-full transition-all duration-300 ${getProgressBarColor(
                          list.completionPercentage
                        )}`}
                        style={{ width: `${list.completionPercentage}%` }}
                        role="progressbar"
                        aria-valuenow={list.completionPercentage}
                        aria-valuemin={0}
                        aria-valuemax={100}
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>作成日: {formatDate(list.createdAt)}</span>
                    {list.canBeCompleted && (
                      <span className="text-green-600 font-medium flex items-center gap-1">
                        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                        </svg>
                        完了可能
                      </span>
                    )}
                  </div>
                </Link>
              ))}
            </div>
          )}

          {/* ポーリング状態の表示 */}
          {!loading && !error && shoppingLists.length > 0 && (
            <div className="mt-6 text-center text-xs text-gray-500">
              自動更新: 30秒ごと
              {isPolling && (
                <span className="ml-2 inline-block w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default ShoppingLists