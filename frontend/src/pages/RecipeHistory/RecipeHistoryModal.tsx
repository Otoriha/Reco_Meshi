import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { formatDistanceToNow } from 'date-fns'
import { ja } from 'date-fns/locale'
import { useToast } from '../../hooks/useToast'
import Toast from '../../components/Toast'
import type { RecipeHistory, UpdateRecipeHistoryParams } from '../../types/recipe'

interface RecipeHistoryModalProps {
  history: RecipeHistory | null
  isOpen: boolean
  onClose: () => void
  onUpdate: (id: number, params: UpdateRecipeHistoryParams) => Promise<void>
  onDelete: (id: number) => Promise<void>
}

const RecipeHistoryModal: React.FC<RecipeHistoryModalProps> = ({
  history,
  isOpen,
  onClose,
  onUpdate,
  onDelete
}) => {
  const [rating, setRating] = useState<number | null>(null)
  const [memo, setMemo] = useState('')
  const [isUpdating, setIsUpdating] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const { toast, showSuccess, showError, hideToast } = useToast()

  useEffect(() => {
    if (history) {
      setRating(history.rating || null)
      setMemo(history.memo || '')
    }
  }, [history])

  if (!isOpen || !history) return null

  const formatRelativeTime = (dateString: string) => {
    try {
      const date = new Date(dateString)
      return formatDistanceToNow(date, { addSuffix: true, locale: ja })
    } catch {
      return '日時不明'
    }
  }

  const formatDateTime = (dateString: string) => {
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('ja-JP', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    } catch {
      return '日時不明'
    }
  }

  const renderStars = (currentRating: number | null, isEditable = false) => {
    return Array.from({ length: 5 }, (_, index) => (
      <button
        key={index}
        onClick={isEditable ? () => setRating(index + 1) : undefined}
        disabled={!isEditable}
        className={`text-3xl transition-colors ${
          currentRating && index < currentRating
            ? 'text-yellow-400'
            : 'text-gray-300'
        } ${isEditable ? 'hover:text-yellow-300 cursor-pointer' : ''}`}
      >
        ★
      </button>
    ))
  }

  const handleUpdate = async () => {
    if (!history) return

    try {
      setIsUpdating(true)
      const params: UpdateRecipeHistoryParams = {}
      
      if (rating !== history.rating) {
        params.rating = rating
      }
      
      if (memo !== (history.memo || '')) {
        params.memo = memo
      }

      if (Object.keys(params).length > 0) {
        await onUpdate(history.id, params)
        showSuccess('調理記録を更新しました')
      }
    } catch (err) {
      showError(err instanceof Error ? err.message : '更新に失敗しました')
    } finally {
      setIsUpdating(false)
    }
  }

  const handleDelete = async () => {
    if (!history) return

    try {
      setIsDeleting(true)
      await onDelete(history.id)
      showSuccess('調理記録を削除しました')
      onClose()
    } catch (err) {
      showError(err instanceof Error ? err.message : '削除に失敗しました')
    } finally {
      setIsDeleting(false)
      setShowDeleteConfirm(false)
    }
  }

  const hasChanges = rating !== history.rating || memo !== (history.memo || '')

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* ヘッダー */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex justify-between items-start">
            <div className="flex-1">
              <h2 className="text-2xl font-bold text-gray-800 line-clamp-2">
                レシピ詳細
              </h2>
              <h3 className="text-lg text-gray-600 mt-2">
                {history.recipe?.title || 'レシピ名不明'}
              </h3>
              <p className="text-sm text-gray-500 mt-2">
                調理日時: {formatDateTime(history.cooked_at)}
              </p>
              <p className="text-xs text-gray-400">
                {formatRelativeTime(history.cooked_at)}
              </p>
            </div>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 ml-4 text-2xl"
            >
              ×
            </button>
          </div>
        </div>

        {/* レシピ情報 */}
        {history.recipe && (
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-700">レシピ情報</h3>
              <Link
                to={`/recipes/${history.recipe_id}`}
                className="text-sm text-blue-600 hover:text-blue-800 font-medium"
              >
                レシピを見る →
              </Link>
            </div>
            <div className="flex items-center space-x-6 text-sm text-gray-600">
              {history.recipe.cooking_time && (
                <span className="flex items-center">
                  <span className="mr-1">⏱</span>
                  {history.recipe.cooking_time}分
                </span>
              )}
              {history.recipe.difficulty && (
                <span>難易度: {history.recipe.difficulty}</span>
              )}
            </div>
          </div>
        )}

        {/* 評価 */}
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-700 mb-4">評価</h3>
          <div className="flex items-center space-x-3">
            {renderStars(rating, true)}
            {rating && (
              <button
                onClick={() => setRating(null)}
                className="text-sm text-gray-500 hover:text-gray-700 ml-4"
              >
                クリア
              </button>
            )}
          </div>
        </div>

        {/* メモ */}
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-700 mb-4">メモ</h3>
          <textarea
            value={memo}
            onChange={(e) => setMemo(e.target.value)}
            placeholder="感想や工夫した点などを記録"
            className="w-full p-4 border border-gray-300 rounded-lg resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            rows={5}
          />
        </div>

        {/* アクション */}
        <div className="p-6">
          <div className="flex flex-col space-y-4">
            {hasChanges && (
              <button
                onClick={handleUpdate}
                disabled={isUpdating}
                className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
              >
                {isUpdating ? '更新中...' : '更新'}
              </button>
            )}
            
            {!showDeleteConfirm ? (
              <button
                onClick={() => setShowDeleteConfirm(true)}
                className="w-full bg-white hover:bg-red-50 text-red-600 border-2 border-red-600 font-semibold py-3 px-6 rounded-lg transition-colors"
              >
                削除
              </button>
            ) : (
              <div className="space-y-3">
                <p className="text-sm text-gray-600 text-center">
                  本当に削除しますか？この操作は取り消せません。
                </p>
                <div className="flex space-x-3">
                  <button
                    onClick={() => setShowDeleteConfirm(false)}
                    className="flex-1 bg-gray-200 hover:bg-gray-300 text-gray-700 font-semibold py-3 px-6 rounded-lg transition-colors"
                  >
                    キャンセル
                  </button>
                  <button
                    onClick={handleDelete}
                    disabled={isDeleting}
                    className="flex-1 bg-red-600 hover:bg-red-700 disabled:bg-gray-400 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
                  >
                    {isDeleting ? '削除中...' : '削除する'}
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
      
      {/* トースト通知 */}
      <Toast
        message={toast.message}
        type={toast.type}
        isVisible={toast.isVisible}
        onClose={hideToast}
      />
    </div>
  )
}

export default RecipeHistoryModal