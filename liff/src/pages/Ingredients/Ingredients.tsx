import React, { useEffect, useMemo, useRef, useState } from 'react'
import liff from '@line/liff'
import type { UserIngredient, UserIngredientGroupedResponse } from '../../types/ingredient'
import { deleteUserIngredient, getUserIngredients, updateUserIngredient } from '../../api/ingredients'
import { imageRecognitionApi } from '../../api/imageRecognition'

const Ingredients: React.FC = () => {
  const [groups, setGroups] = useState<Record<string, UserIngredient[]>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [editValue, setEditValue] = useState<{ quantity: number }>({ quantity: 0 })

  // 画像認識関連の状態
  const fileInputRef = useRef<HTMLInputElement | null>(null)
  const [isUploading, setIsUploading] = useState(false)
  const [uploadMessage, setUploadMessage] = useState<string | null>(null)
  const [isInLiffClient, setIsInLiffClient] = useState(false)

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
    // LIFF環境チェック
    setIsInLiffClient(liff.isInClient())
  }, [])

  const handleImageUpload = () => {
    fileInputRef.current?.click()
  }

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files
    if (!files || files.length === 0) return

    // ファイルサイズチェック（20MB制限）
    const MAX_FILE_SIZE = 20 * 1024 * 1024 // 20MB
    const oversizedFiles = Array.from(files).filter((file) => file.size > MAX_FILE_SIZE)
    if (oversizedFiles.length > 0) {
      setError('ファイルサイズは20MB以下にしてください。')
      event.target.value = ''
      return
    }

    setIsUploading(true)
    setUploadMessage(null)
    setError(null)

    try {
      const images = Array.from(files)
      const response =
        images.length === 1
          ? await imageRecognitionApi.recognizeIngredients(images[0])
          : await imageRecognitionApi.recognizeMultipleIngredients(images)

      if (response.success) {
        const recognized = response.recognized_ingredients
          .map((ingredient) => `${ingredient.name}(${Math.round(ingredient.confidence * 100)}%)`)
          .join('、')
        setUploadMessage(
          recognized.length > 0
            ? `識別された食材: ${recognized}`
            : '食材を識別できませんでした。写真を確認してください。'
        )
        // 在庫リストを再取得
        await fetchData()
      } else {
        setError(response.message ?? '画像の認識に失敗しました。')
      }
    } catch (e) {
      console.error(e)
      setError('画像のアップロードに失敗しました。通信環境をご確認ください。')
    } finally {
      setIsUploading(false)
      // 同じファイルを再度選択できるようにするために値をリセット
      event.target.value = ''
    }
  }

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

        {/* 画像認識セクション */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">
            {isInLiffClient ? 'カメラで食材を追加' : '写真から食材を追加'}
          </h2>
          <p className="text-sm text-gray-600 mb-4">
            {isInLiffClient
              ? '冷蔵庫の写真を撮影すると、AIが自動で食材を認識します。'
              : '冷蔵庫の写真を選択すると、AIが自動で食材を認識します。'}
          </p>

          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            capture="environment"
            multiple
            className="hidden"
            onChange={handleFileChange}
          />

          <button
            onClick={handleImageUpload}
            className="w-full bg-green-600 text-white px-4 py-3 rounded-md hover:bg-green-700 transition-colors font-medium disabled:opacity-70 disabled:cursor-not-allowed"
            disabled={isUploading}
          >
            {isUploading ? 'アップロード中...' : isInLiffClient ? 'カメラ起動' : '写真を選択'}
          </button>

          {uploadMessage && (
            <div className="mt-4 p-3 rounded bg-green-50 text-green-700 border border-green-200">
              {uploadMessage}
            </div>
          )}
        </div>

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
