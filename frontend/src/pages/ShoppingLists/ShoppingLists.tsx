import React, { useEffect, useState, useRef, useCallback } from 'react'
import { Link } from 'react-router-dom'
import type { ShoppingListSummary } from '../../types/shoppingList'
import { getShoppingLists, getShoppingListErrorMessage } from '../../api/shoppingLists'
import { FaEye } from 'react-icons/fa'

const POLLING_INTERVAL = 30000 // 30秒

const ShoppingLists: React.FC = () => {
  const [shoppingLists, setShoppingLists] = useState<ShoppingListSummary[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isPolling, setIsPolling] = useState(false)
  const [activeTab, setActiveTab] = useState<'in_progress' | 'completed'>('in_progress')
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
      let lists: ShoppingListSummary[] = []

      if (activeTab === 'in_progress') {
        // 未完了・進行中のリストを取得
        const [pendingLists, inProgressLists] = await Promise.all([
          getShoppingLists({ status: 'pending', per_page: 50 }),
          getShoppingLists({ status: 'in_progress', per_page: 50 })
        ])
        lists = [...pendingLists, ...inProgressLists]
      } else {
        // 完了済みのリストを取得
        lists = await getShoppingLists({ status: 'completed', per_page: 50 })
      }

      // 作成日時でソート
      const sortedLists = lists.sort((a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      )

      if (isMountedRef.current) {
        setShoppingLists(sortedLists)
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
  }, [isPolling, activeTab])

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

  // タブ変更時にデータを再取得
  useEffect(() => {
    fetchShoppingLists()
  }, [activeTab, fetchShoppingLists])


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

  const handleSendToLine = (listId: number) => {
    console.log('LINEに送る:', listId)
    // TODO: LINEに送る機能の実装
  }

  const handleCompleteList = (listId: number) => {
    console.log('買い物完了:', listId)
    // TODO: 買い物完了機能の実装
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* ヘッダー */}
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">買い物リスト</h1>

          {/* タブ */}
          <div className="border-b border-gray-200">
            <nav className="-mb-px flex space-x-8">
              <button
                onClick={() => setActiveTab('in_progress')}
                className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
                  activeTab === 'in_progress'
                    ? 'border-green-500 text-green-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                進行中
              </button>
              <button
                onClick={() => setActiveTab('completed')}
                className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
                  activeTab === 'completed'
                    ? 'border-green-500 text-green-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                完了済み
              </button>
            </nav>
          </div>
        </div>

        {/* コンテンツ */}
        <div className="space-y-4">
          {loading && (
            <div className="text-center py-12">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-green-600"></div>
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
              <p className="text-gray-600 mt-4 text-lg">
                {activeTab === 'in_progress' ? '進行中の買い物リストがありません' : '完了済みの買い物リストがありません'}
              </p>
              <p className="text-sm text-gray-500 mt-2">
                レシピから買い物リストを作成してみましょう
              </p>
            </div>
          )}

          {!loading && !error && shoppingLists.length > 0 && (
            shoppingLists.map((list) => (
              <div
                key={list.id}
                className="bg-white rounded-lg shadow-sm border border-gray-200 p-6"
              >
                {/* ヘッダー */}
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-xl">🛒</span>
                      <h3 className="font-bold text-lg text-gray-900">
                        {list.displayTitle}
                      </h3>
                    </div>
                    <p className="text-sm text-gray-600">
                      {formatDate(list.createdAt)} 作成
                    </p>
                  </div>
                  <button
                    onClick={() => handleSendToLine(list.id)}
                    className="bg-green-500 text-white px-4 py-2 rounded-lg hover:bg-green-600 transition-colors text-sm font-medium"
                  >
                    LINEに送る
                  </button>
                </div>

                {/* 必須の材料 */}
                {list.recipe && (
                  <div className="mb-4">
                    <h4 className="font-medium text-gray-900 mb-2">必須の材料</h4>
                    <div className="space-y-2">
                      {/* サンプルアイテム - 実際はAPIからのデータを使用 */}
                      <div className="flex items-center gap-2">
                        <input type="checkbox" className="w-4 h-4 text-green-600 rounded" />
                        <span className="text-gray-900">カレールー（中辛）1箱</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <input type="checkbox" className="w-4 h-4 text-green-600 rounded" />
                        <span className="text-gray-900">豚肉（カレー用）300g</span>
                      </div>
                    </div>
                  </div>
                )}

                {/* お好みで追加 */}
                <div className="mb-4">
                  <h4 className="font-medium text-gray-900 mb-2">お好みで追加</h4>
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <input type="checkbox" className="w-4 h-4 text-green-600 rounded" />
                      <span className="text-gray-900">福神漬け</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <input type="checkbox" className="w-4 h-4 text-green-600 rounded" />
                      <span className="text-gray-900">らっきょう</span>
                    </div>
                  </div>
                </div>

                {/* 進捗状況 */}
                <div className="mb-4">
                  <div className="flex items-center justify-between text-sm text-gray-600 mb-2">
                    <span>進捗状況</span>
                    <span className="font-medium text-green-600">{list.completionPercentage}% 完了</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-green-500 h-2 rounded-full transition-all duration-300"
                      style={{ width: `${list.completionPercentage}%` }}
                    />
                  </div>
                </div>

                {/* アクションボタン */}
                {activeTab === 'in_progress' && (
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleCompleteList(list.id)}
                      className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors text-sm font-medium flex items-center gap-2"
                    >
                      ✓ 買い物完了
                    </button>
                    <Link
                      to={`/shopping-lists/${list.id}`}
                      className="bg-gray-100 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-200 transition-colors text-sm font-medium flex items-center gap-2"
                    >
                      <FaEye className="w-4 h-4" />
                      詳細を見る
                    </Link>
                  </div>
                )}
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  )
}

export default ShoppingLists