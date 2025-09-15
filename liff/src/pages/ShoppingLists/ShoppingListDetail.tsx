import React, { useEffect, useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import type { ShoppingList, ShoppingListItem } from '../../types/shoppingList'
import {
  getShoppingList,
  updateShoppingListItem,
  completeShoppingList
} from '../../api/shoppingLists'

const ShoppingListDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [shoppingList, setShoppingList] = useState<ShoppingList | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [updatingItems, setUpdatingItems] = useState<Set<number>>(new Set())
  const [completing, setCompleting] = useState(false)

  const fetchShoppingList = async () => {
    if (!id) return

    setLoading(true)
    setError(null)
    try {
      const list = await getShoppingList(Number(id))
      setShoppingList(list)
    } catch (e) {
      console.error(e)
      setError('買い物リストの取得に失敗しました。')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchShoppingList()
  }, [id])

  const handleItemCheck = async (item: ShoppingListItem, checked: boolean) => {
    if (!shoppingList || updatingItems.has(item.id)) return

    // 楽観的更新: UIを即座に更新
    const optimisticItems = shoppingList.shoppingListItems?.map(i =>
      i.id === item.id
        ? {
            ...i,
            isChecked: checked,
            checkedAt: checked ? new Date().toISOString() : null
          }
        : i
    ) || []

    setShoppingList(prev => prev ? {
      ...prev,
      shoppingListItems: optimisticItems,
      // 進捗も即座に更新
      completionPercentage: calculateCompletionPercentage(optimisticItems),
      uncheckedItemsCount: optimisticItems.filter(i => !i.isChecked).length,
      canBeCompleted: optimisticItems.every(i => i.isChecked) && optimisticItems.length > 0
    } : null)

    setUpdatingItems(prev => new Set([...prev, item.id]))

    try {
      const updatedItem = await updateShoppingListItem(
        shoppingList.id,
        item.id,
        {
          isChecked: checked,
          lockVersion: item.lockVersion
        }
      )

      // サーバーからの正確な値で更新
      setShoppingList(prev => {
        if (!prev) return null
        const serverItems = prev.shoppingListItems?.map(i =>
          i.id === updatedItem.id ? updatedItem : i
        ) || []
        
        return {
          ...prev,
          shoppingListItems: serverItems,
          completionPercentage: calculateCompletionPercentage(serverItems),
          uncheckedItemsCount: serverItems.filter(i => !i.isChecked).length,
          canBeCompleted: serverItems.every(i => i.isChecked) && serverItems.length > 0
        }
      })
    } catch (e: any) {
      console.error(e)
      
      // エラー時のロールバック
      const originalItems = shoppingList.shoppingListItems?.map(i =>
        i.id === item.id ? item : i
      ) || []

      setShoppingList(prev => prev ? {
        ...prev,
        shoppingListItems: originalItems,
        completionPercentage: calculateCompletionPercentage(originalItems),
        uncheckedItemsCount: originalItems.filter(i => !i.isChecked).length,
        canBeCompleted: originalItems.every(i => i.isChecked) && originalItems.length > 0
      } : null)

      // 409エラー（楽観的ロック）の場合は再取得を促す
      if (e.response?.status === 409) {
        setError('他のユーザーによって更新されています。画面を再読み込みして最新の状態を確認してください。')
      } else {
        setError('アイテムの更新に失敗しました。')
      }
    } finally {
      setUpdatingItems(prev => {
        const next = new Set(prev)
        next.delete(item.id)
        return next
      })
    }
  }

  const handleComplete = async () => {
    if (!shoppingList || completing) return

    setCompleting(true)
    setError(null)

    try {
      const completedList = await completeShoppingList(shoppingList.id)
      setShoppingList(completedList)
      
      // 完了したら一覧に戻る
      setTimeout(() => {
        navigate('/shopping-lists')
      }, 1500)
    } catch (e) {
      console.error(e)
      setError('完了処理に失敗しました。')
    } finally {
      setCompleting(false)
    }
  }

  const calculateCompletionPercentage = (items: ShoppingListItem[]): number => {
    if (items.length === 0) return 0
    const checkedCount = items.filter(item => item.isChecked).length
    return Math.round((checkedCount / items.length) * 100)
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

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <p className="text-gray-600">読み込み中...</p>
      </div>
    )
  }

  if (!shoppingList) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-600 mb-4">買い物リストが見つかりません</p>
          <Link
            to="/shopping-lists"
            className="text-blue-600 hover:text-blue-800 underline"
          >
            一覧に戻る
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="container mx-auto px-4 py-8">
        <div className="mb-6">
          <Link
            to="/shopping-lists"
            className="text-blue-600 hover:text-blue-800 text-sm mb-2 inline-block"
          >
            ← 一覧に戻る
          </Link>
          <h1 className="text-2xl font-bold text-gray-800">
            {shoppingList.displayTitle}
          </h1>
          {shoppingList.recipe && (
            <p className="text-gray-600 mt-1">
              レシピ: {shoppingList.recipe.title}
            </p>
          )}
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          {error && (
            <div className="mb-4 p-3 rounded bg-red-50 text-red-700 border border-red-200">
              {error}
              <button
                onClick={fetchShoppingList}
                className="ml-2 text-red-800 underline hover:no-underline"
              >
                再読み込み
              </button>
            </div>
          )}

          {/* 進捗表示 */}
          <div className="mb-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-700">
                進捗: {shoppingList.totalItemsCount - shoppingList.uncheckedItemsCount} / {shoppingList.totalItemsCount} 項目
              </span>
              <span className="text-sm font-medium text-gray-700">
                {shoppingList.completionPercentage}%
              </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-3">
              <div
                className="bg-blue-500 h-3 rounded-full transition-all duration-300"
                style={{ width: `${shoppingList.completionPercentage}%` }}
              />
            </div>
          </div>

          {/* 完了ボタン */}
          {shoppingList.canBeCompleted && shoppingList.status !== 'completed' && (
            <div className="mb-6">
              <button
                onClick={handleComplete}
                disabled={completing}
                className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white font-medium py-3 px-4 rounded-lg transition-colors"
              >
                {completing ? '完了処理中...' : '買い物完了'}
              </button>
            </div>
          )}

          {/* アイテムリスト */}
          <div className="space-y-3">
            {shoppingList.shoppingListItems?.map((item) => (
              <div
                key={item.id}
                className={`flex items-center p-3 border rounded-lg transition-colors ${
                  item.isChecked
                    ? 'bg-green-50 border-green-200'
                    : 'bg-white border-gray-200'
                }`}
              >
                <div className="flex items-center flex-1">
                  <input
                    type="checkbox"
                    checked={item.isChecked}
                    onChange={(e) => handleItemCheck(item, e.target.checked)}
                    disabled={updatingItems.has(item.id)}
                    className="h-5 w-5 text-blue-600 rounded focus:ring-blue-500 mr-3"
                  />
                  <div className="flex-1">
                    <span
                      className={`font-medium ${
                        item.isChecked
                          ? 'text-green-800 line-through'
                          : 'text-gray-900'
                      }`}
                    >
                      {item.ingredient?.displayNameWithEmoji || item.ingredient?.displayName || item.ingredient?.name || '不明な食材'}
                    </span>
                    <div className="text-sm text-gray-600 mt-1">
                      <span>{item.displayQuantityWithUnit}</span>
                      {item.ingredient?.category && (
                        <span className="ml-2 px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs">
                          {item.ingredient.category}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
                {updatingItems.has(item.id) && (
                  <div className="ml-2">
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600" />
                  </div>
                )}
                {item.checkedAt && (
                  <div className="ml-2 text-xs text-gray-500">
                    {formatDate(item.checkedAt)}
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* 完了済みの場合のメッセージ */}
          {shoppingList.status === 'completed' && (
            <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg">
              <p className="text-green-800 font-medium text-center">
                🎉 買い物が完了しました！
              </p>
            </div>
          )}
        </div>

        {/* メタ情報 */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="font-medium text-gray-900 mb-3">詳細情報</h3>
          <div className="grid grid-cols-1 gap-3 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">ステータス:</span>
              <span className="font-medium">{shoppingList.statusDisplay}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">作成日:</span>
              <span>{formatDate(shoppingList.createdAt)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">更新日:</span>
              <span>{formatDate(shoppingList.updatedAt)}</span>
            </div>
            {shoppingList.note && (
              <div>
                <span className="text-gray-600 block mb-1">メモ:</span>
                <p className="text-gray-900">{shoppingList.note}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default ShoppingListDetail