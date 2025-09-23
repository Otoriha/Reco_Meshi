import React, { useEffect, useState, useRef, useCallback } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import type { ShoppingList, ShoppingListItem } from '../../types/shoppingList'
import {
  getShoppingList,
  updateShoppingListItem,
  completeShoppingList,
  getShoppingListErrorMessage
} from '../../api/shoppingLists'

const POLLING_INTERVAL = 15000 // 15秒（詳細画面は短めに）

const ShoppingListDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [shoppingList, setShoppingList] = useState<ShoppingList | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [updatingItems, setUpdatingItems] = useState<Set<number>>(new Set())
  const [completing, setCompleting] = useState(false)
  const [isPolling, setIsPolling] = useState(false)
  const pollingTimerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const isMountedRef = useRef(true)
  const editingItemsRef = useRef<Set<number>>(new Set())

  const calculateCompletionPercentage = (items: ShoppingListItem[]): number => {
    if (items.length === 0) return 0
    const checkedCount = items.filter(item => item.isChecked).length
    return Math.round((checkedCount / items.length) * 100)
  }

  const applyItemUpdates = (base: ShoppingList, items: ShoppingListItem[]): ShoppingList => {
    const completionPercentage = calculateCompletionPercentage(items)
    const uncheckedItemsCount = items.filter(item => !item.isChecked).length
    const canBeCompleted = items.length > 0 && items.every(item => item.isChecked)

    return {
      ...base,
      shoppingListItems: items,
      completionPercentage,
      uncheckedItemsCount,
      canBeCompleted,
      totalItemsCount: items.length
    }
  }

  const fetchShoppingList = useCallback(async (showLoading = true) => {
    if (!id) return
    
    // ポーリング中の重複リクエストを防ぐ
    if (isPolling && !showLoading) return

    if (showLoading) {
      setLoading(true)
    }
    setError(null)
    setIsPolling(true)

    try {
      const list = await getShoppingList(Number(id))

      if (isMountedRef.current) {
        setShoppingList(prev => {
          const nextItems = list.shoppingListItems ?? []

          if (!prev) {
            return applyItemUpdates(list, nextItems)
          }

          const currentItems = prev.shoppingListItems ?? []
          const mergedItems = nextItems.map(newItem => {
            const currentItem = currentItems.find(item => item.id === newItem.id)
            if (!currentItem) {
              return newItem
            }

            const isEditing = editingItemsRef.current.has(newItem.id)
            const currentLockVersion = currentItem.lockVersion ?? 0
            const newLockVersion = newItem.lockVersion ?? 0
            const currentUpdatedAt = currentItem.updatedAt ? new Date(currentItem.updatedAt).getTime() : 0
            const newUpdatedAt = newItem.updatedAt ? new Date(newItem.updatedAt).getTime() : 0

            if (
              isEditing ||
              currentLockVersion >= newLockVersion ||
              currentUpdatedAt >= newUpdatedAt
            ) {
              return currentItem
            }

            return newItem
          })

          return applyItemUpdates(list, mergedItems)
        })
      }
    } catch (e) {
      console.error('買い物リスト詳細取得エラー:', e)
      if (isMountedRef.current) {
        setError(getShoppingListErrorMessage(e))
      }
    } finally {
      if (isMountedRef.current) {
        setLoading(false)
        setIsPolling(false)
      }
    }
  }, [id, isPolling])

  // ポーリングの設定
  const startPolling = useCallback(() => {
    if (pollingTimerRef.current) {
      clearInterval(pollingTimerRef.current)
    }

    pollingTimerRef.current = setInterval(() => {
      fetchShoppingList(false)
    }, POLLING_INTERVAL)
  }, [fetchShoppingList])

  const stopPolling = useCallback(() => {
    if (pollingTimerRef.current) {
      clearInterval(pollingTimerRef.current)
      pollingTimerRef.current = null
    }
  }, [])

  useEffect(() => {
    isMountedRef.current = true
    fetchShoppingList()
    startPolling()

    return () => {
      isMountedRef.current = false
      stopPolling()
    }
  }, [id])

  const handleItemCheck = async (item: ShoppingListItem, checked: boolean) => {
    if (!shoppingList || updatingItems.has(item.id)) return

    // 編集中フラグを立てる
    editingItemsRef.current.add(item.id)

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

    setShoppingList(prev => {
      if (!prev) return prev
      return applyItemUpdates(prev, optimisticItems)
    })

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
        if (!prev) return prev
        const serverItems = prev.shoppingListItems?.map(i =>
          i.id === updatedItem.id ? updatedItem : i
        ) || []

        return applyItemUpdates(prev, serverItems)
      })
    } catch (e) {
      console.error('アイテム更新エラー:', e)
      
      // エラー時のロールバック
      const originalItems = shoppingList.shoppingListItems?.map(i =>
        i.id === item.id ? item : i
      ) || []

      setShoppingList(prev => {
        if (!prev) return prev
        return applyItemUpdates(prev, originalItems)
      })

      // エラーメッセージの設定
      const err = e as { response?: { status?: number } }
      if (err.response?.status === 409) {
        setError('他のユーザーによって更新されています。')
      } else {
        setError(getShoppingListErrorMessage(e))
      }
    } finally {
      // 編集中フラグを解除
      editingItemsRef.current.delete(item.id)
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
      console.error('完了処理エラー:', e)
      setError(getShoppingListErrorMessage(e))
    } finally {
      setCompleting(false)
    }
  }

  const handleRefresh = async () => {
    if (!id) return
    
    // 編集中のアイテムをクリア（強制的に最新データを取得）
    editingItemsRef.current.clear()
    setError(null)
    
    await fetchShoppingList()
    // ポーリングタイマーをリセット
    startPolling()
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
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="text-gray-600 mt-4">読み込み中...</p>
        </div>
      </div>
    )
  }

  if (!shoppingList) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
          <p className="text-gray-600 mt-4 mb-4">買い物リストが見つかりません</p>
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
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <div className="mb-6">
          <Link
            to="/shopping-lists"
            className="text-blue-600 hover:text-blue-800 text-sm mb-3 inline-flex items-center gap-1"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            一覧に戻る
          </Link>
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold text-gray-800">
                {shoppingList.displayTitle}
              </h1>
              {shoppingList.recipe && (
                <p className="text-gray-600 mt-2">
                  <span className="inline-flex items-center gap-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                    </svg>
                    レシピ: {shoppingList.recipe.title}
                  </span>
                </p>
              )}
            </div>
            <button
              onClick={handleRefresh}
              disabled={loading || isPolling}
              className="px-3 py-1.5 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 disabled:bg-gray-100 transition-colors flex items-center gap-1 text-sm"
              aria-label="リストを更新"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              更新
            </button>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          {error && (
            <div className="mb-4 p-4 rounded-lg bg-red-50 text-red-700 border border-red-200">
              <div className="flex items-start gap-2">
                <svg className="w-5 h-5 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
                <div className="flex-1">
                  <p>{error}</p>
                  {error.includes('他のユーザー') && (
                    <button
                      onClick={handleRefresh}
                      className="mt-2 text-red-800 underline hover:no-underline text-sm"
                    >
                      最新の状態を取得
                    </button>
                  )}
                </div>
              </div>
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
                role="progressbar"
                aria-valuenow={shoppingList.completionPercentage}
                aria-valuemin={0}
                aria-valuemax={100}
              />
            </div>
          </div>

          {/* 完了ボタン */}
          {shoppingList.canBeCompleted && shoppingList.status !== 'completed' && (
            <div className="mb-6">
              <button
                onClick={handleComplete}
                disabled={completing}
                className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white font-medium py-3 px-4 rounded-lg transition-colors flex items-center justify-center gap-2"
              >
                {completing ? (
                  <>
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                    完了処理中...
                  </>
                ) : (
                  <>
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                    買い物完了（在庫に反映）
                  </>
                )}
              </button>
              <p className="text-xs text-gray-500 text-center mt-2">
                完了すると、チェック済みのアイテムが在庫に追加されます
              </p>
            </div>
          )}

          {/* アイテムリスト */}
          <div className="space-y-3">
            {shoppingList.shoppingListItems?.map((item) => (
              (() => {
                const ingredientLabel =
                  item.ingredient?.displayNameWithEmoji ||
                  item.ingredient?.displayName ||
                  item.ingredient?.name ||
                  item.ingredientDisplayName ||
                  item.ingredientDisplayNameText ||
                  item.ingredientName ||
                  '不明な食材'

                const ingredientEmoji =
                  item.ingredient?.emoji ||
                  item.ingredientEmoji ||
                  null

                const quantityLabel = (item.displayQuantityWithUnit || '').trim()

                return (
              <div
                key={item.id}
                className={`flex items-center p-4 border rounded-lg transition-colors ${
                  item.isChecked
                    ? 'bg-green-50 border-green-200'
                    : 'bg-white border-gray-200 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center flex-1">
                  <label className="flex items-center cursor-pointer flex-1">
                    <input
                      type="checkbox"
                      checked={item.isChecked}
                      onChange={(e) => handleItemCheck(item, e.target.checked)}
                      disabled={updatingItems.has(item.id) || shoppingList.status === 'completed'}
                      className="h-5 w-5 text-blue-600 rounded focus:ring-blue-500 mr-3 cursor-pointer"
                      aria-label={`${ingredientLabel}をチェック`}
                    />
                    {ingredientEmoji && (
                      <span className="mr-3 text-xl" aria-hidden="true">
                        {ingredientEmoji}
                      </span>
                    )}
                    <div className="flex-1">
                      <span
                        className={`font-medium ${
                          item.isChecked
                            ? 'text-green-800 line-through'
                            : 'text-gray-900'
                        }`}
                      >
                        {ingredientLabel}
                      </span>
                      <div className="flex items-center gap-3 text-sm text-gray-600 mt-1">
                        {quantityLabel && <span>{quantityLabel}</span>}
                      </div>
                    </div>
                  </label>
                </div>
                {updatingItems.has(item.id) && (
                  <div className="ml-3">
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600" />
                  </div>
                )}
                {item.checkedAt && !updatingItems.has(item.id) && (
                  <div className="ml-3 text-xs text-gray-500">
                    <svg className="w-4 h-4 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                  </div>
                )}
              </div>
                )
              })()
            ))}
          </div>

          {/* 完了済みの場合のメッセージ */}
          {shoppingList.status === 'completed' && (
            <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg">
              <p className="text-green-800 font-medium text-center flex items-center justify-center gap-2">
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                買い物が完了しました！
              </p>
            </div>
          )}
        </div>

        {/* メタ情報 */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="font-semibold text-gray-900 mb-4">詳細情報</h3>
          <div className="grid grid-cols-1 gap-3 text-sm">
            <div className="flex justify-between py-2 border-b border-gray-100">
              <span className="text-gray-600">ステータス:</span>
              <span className="font-medium">{shoppingList.statusDisplay}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-gray-100">
              <span className="text-gray-600">作成日:</span>
              <span>{formatDate(shoppingList.createdAt)}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-gray-100">
              <span className="text-gray-600">更新日:</span>
              <span>{formatDate(shoppingList.updatedAt)}</span>
            </div>
            {shoppingList.note && (
              <div className="py-2">
                <span className="text-gray-600 block mb-1">メモ:</span>
                <p className="text-gray-900 whitespace-pre-wrap">{shoppingList.note}</p>
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  )
}

export default ShoppingListDetail
