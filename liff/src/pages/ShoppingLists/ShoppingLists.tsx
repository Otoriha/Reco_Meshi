import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import type { ShoppingListSummary } from '../../types/shoppingList'
import { getShoppingLists } from '../../api/shoppingLists'

const ShoppingLists: React.FC = () => {
  const [shoppingLists, setShoppingLists] = useState<ShoppingListSummary[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchShoppingLists = async () => {
    setLoading(true)
    setError(null)
    try {
      // 未完了・進行中のリストを取得
      const activeStatuses = ['pending', 'in_progress'] as const
      const allLists = await Promise.all(
        activeStatuses.map(status => getShoppingLists({ status }))
      )
      
      // 結果をマージして作成日時でソート
      const mergedLists = allLists.flat().sort((a, b) => 
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      )
      
      setShoppingLists(mergedLists)
    } catch (e) {
      console.error(e)
      setError('買い物リストの取得に失敗しました。通信環境をご確認ください。')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchShoppingLists()
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

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">買い物リスト</h1>

        <div className="bg-white rounded-lg shadow-md p-6">
          {loading && (
            <div className="text-center py-8">
              <p className="text-gray-600">読み込み中...</p>
            </div>
          )}

          {!loading && error && (
            <div className="mb-4 p-3 rounded bg-red-50 text-red-700 border border-red-200">
              {error}
              <button
                onClick={fetchShoppingLists}
                className="ml-2 text-red-800 underline hover:no-underline"
              >
                再試行
              </button>
            </div>
          )}

          {!loading && !error && shoppingLists.length === 0 && (
            <div className="text-center py-8">
              <p className="text-gray-600 mb-4">買い物リストがありません</p>
              <p className="text-sm text-gray-500">
                レシピから買い物リストを作成してみましょう
              </p>
            </div>
          )}

          {!loading && !error && shoppingLists.length > 0 && (
            <div className="space-y-4">
              {shoppingLists.map((list) => (
                <Link
                  key={list.id}
                  to={`/shopping-lists/${list.id}`}
                  className="block border border-gray-200 rounded-lg p-4 hover:bg-gray-50 hover:border-gray-300 transition-colors"
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <h3 className="font-medium text-gray-900 mb-1">
                        {list.displayTitle}
                      </h3>
                      {list.recipe && (
                        <p className="text-sm text-gray-600">
                          レシピ: {list.recipe.title}
                        </p>
                      )}
                    </div>
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(
                        list.status
                      )}`}
                    >
                      {list.statusDisplay}
                    </span>
                  </div>

                  <div className="mb-3">
                    <div className="flex items-center justify-between text-sm text-gray-600 mb-1">
                      <span>進捗: {list.totalItemsCount - list.uncheckedItemsCount} / {list.totalItemsCount} 項目</span>
                      <span>{list.completionPercentage}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full transition-all duration-300 ${getProgressBarColor(
                          list.completionPercentage
                        )}`}
                        style={{ width: `${list.completionPercentage}%` }}
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <span>作成日: {formatDate(list.createdAt)}</span>
                    {list.canBeCompleted && (
                      <span className="text-green-600 font-medium">
                        完了可能
                      </span>
                    )}
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default ShoppingLists