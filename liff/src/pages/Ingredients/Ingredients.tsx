import React, { useEffect, useMemo, useState } from 'react'
import type { UserIngredient, UserIngredientGroupedResponse } from '../../types/ingredient'
import { deleteUserIngredient, getUserIngredients, updateUserIngredient } from '../../api/ingredients'

const Ingredients: React.FC = () => {
  const [groups, setGroups] = useState<Record<string, UserIngredient[]>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [editValue, setEditValue] = useState<{ quantity: number }>({ quantity: 0 })

  const totalCount = useMemo(() => {
    return Object.values(groups).reduce((sum, arr) => sum + arr.length, 0)
  }, [groups])

  const fetchData = async () => {
    setLoading(true)
    setError(null)
    try {
      const res = (await getUserIngredients('category')) as UserIngredientGroupedResponse
      setGroups(res.data)
    } catch (e) {
      console.error(e)
      setError('在庫の取得に失敗しました。通信環境をご確認ください。')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [])

  const startEdit = (item: UserIngredient) => {
    setEditingId(item.id)
    setEditValue({ quantity: item.quantity ?? 0 })
  }

  const cancelEdit = () => {
    setEditingId(null)
  }

  const saveEdit = async (item: UserIngredient) => {
    try {
      const q = Number(editValue.quantity)
      if (Number.isNaN(q) || q <= 0) {
        setError('数量は0より大きい数値で入力してください。')
        return
      }
      const res = await updateUserIngredient(item.id, { quantity: q })
      const updated = res.data
      // 状態更新（同カテゴリ内の置換）
      const category = item.ingredient?.category ?? 'その他'
      setGroups((prev) => {
        const arr = prev[category] || []
        const nextArr = arr.map((i) => (i.id === updated.id ? updated : i))
        return { ...prev, [category]: nextArr }
      })
      setEditingId(null)
      setError(null)
    } catch (e) {
      console.error(e)
      setError('更新に失敗しました。時間をおいて再度お試しください。')
    }
  }

  const handleDelete = async (item: UserIngredient) => {
    const ok = window.confirm('この食材を削除しますか？')
    if (!ok) return
    try {
      await deleteUserIngredient(item.id)
      const category = item.ingredient?.category ?? 'その他'
      setGroups((prev) => {
        const arr = prev[category] || []
        const nextArr = arr.filter((i) => i.id !== item.id)
        const next = { ...prev }
        if (nextArr.length > 0) {
          next[category] = nextArr
        } else {
          // 空になったカテゴリは削除
          delete next[category]
        }
        return next
      })
    } catch (e) {
      console.error(e)
      setError('削除に失敗しました。')
    }
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">食材リスト</h1>

        <div className="bg-white rounded-lg shadow-md p-6">
          {loading && <p className="text-gray-600">読み込み中...</p>}

          {!loading && error && (
            <div className="mb-4 p-3 rounded bg-red-50 text-red-700 border border-red-200">
              {error}
            </div>
          )}

          {!loading && totalCount === 0 && (
            <p className="text-gray-600">食材がありません。</p>
          )}

          {!loading && totalCount > 0 && (
            <div className="space-y-8">
              {Object.keys(groups).sort().map((category) => (
                <div key={category}>
                  <h2 className="text-xl font-semibold text-gray-700 mb-4">{category || 'その他'}</h2>

                  <div className="grid grid-cols-1 gap-4">
                    {groups[category].map((item) => {
                      const isExpired = item.expired
                      const isSoon = item.expiring_soon
                      const bg = isExpired
                        ? 'bg-red-50 border-red-200'
                        : isSoon
                        ? 'bg-yellow-50 border-yellow-200'
                        : 'bg-gray-50 border-gray-200'
                      const name = item.ingredient?.display_name_with_emoji || item.display_name
                      return (
                        <div key={item.id} className={`border ${bg} rounded p-4 flex items-center justify-between`}>
                          <div>
                            <div className="text-gray-800 font-medium">{name}</div>
                            <div className="text-sm text-gray-600 mt-1">
                              {item.days_until_expiry != null ? (
                                <span>期限まで {item.days_until_expiry} 日</span>
                              ) : (
                                <span>期限未設定</span>
                              )}
                            </div>
                          </div>

                          <div className="flex items-center gap-2">
                            {editingId === item.id ? (
                              <>
                                <input
                                  type="number"
                                  step="any"
                                  className="w-24 px-2 py-1 border rounded"
                                  value={editValue.quantity}
                                  onChange={(e) => setEditValue({ quantity: Number(e.target.value) })}
                                />
                                <button
                                  className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700"
                                  onClick={() => saveEdit(item)}
                                >
                                  保存
                                </button>
                                <button
                                  className="px-3 py-1 bg-gray-300 text-gray-800 rounded hover:bg-gray-400"
                                  onClick={cancelEdit}
                                >
                                  キャンセル
                                </button>
                              </>
                            ) : (
                              <>
                                <span className="text-gray-800 mr-2">{item.formatted_quantity}</span>
                                <button
                                  className="px-3 py-1 bg-indigo-600 text-white rounded hover:bg-indigo-700"
                                  onClick={() => startEdit(item)}
                                >
                                  編集
                                </button>
                              </>
                            )}
                            <button
                              className="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700"
                              onClick={() => handleDelete(item)}
                            >
                              削除
                            </button>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default Ingredients
