import React from 'react'
import type { RecipeHistory } from '../../types/recipe'
import { FaStar, FaRegStar, FaClock } from 'react-icons/fa'

interface RecipeHistoryItemProps {
  history: RecipeHistory
  onClick: () => void
  onRatingChange?: (rating: number | null) => void
  onDelete?: () => void
}

const RecipeHistoryItem: React.FC<RecipeHistoryItemProps> = ({
  history,
  onClick,
  onRatingChange,
  onDelete
}) => {
  const formatDate = (dateString: string) => {
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('ja-JP', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        weekday: 'short',
        hour: '2-digit',
        minute: '2-digit'
      })
    } catch {
      return '日時不明'
    }
  }

  const renderStars = (rating?: number | null, isEditable = false) => {
    const normalized = rating ? Math.max(0, Math.min(5, Math.round(rating))) : 0

    return (
      <div className="flex items-center gap-1">
        {Array.from({ length: 5 }, (_, index) => (
          <button
            key={index}
            onClick={isEditable && onRatingChange ? (e) => {
              e.stopPropagation()
              onRatingChange(index + 1)
            } : undefined}
            disabled={!isEditable || !onRatingChange}
            className={`${
              isEditable && onRatingChange
                ? 'hover:text-yellow-300 cursor-pointer transition-colors'
                : 'cursor-default'
            }`}
          >
            <span className={`${
              index < normalized ? 'text-yellow-400' : 'text-gray-300'
            }`}>
              {index < normalized ? <FaStar className="w-4 h-4" /> : <FaRegStar className="w-4 h-4" />}
            </span>
          </button>
        ))}
        {isEditable && rating && onRatingChange && (
          <button
            onClick={(e) => {
              e.stopPropagation()
              onRatingChange(null)
            }}
            className="ml-2 text-xs text-gray-500 hover:text-gray-700 transition-colors"
          >
            クリア
          </button>
        )}
      </div>
    )
  }

  // レシピのタイトルに基づいて絵文字を選択（簡易版）
  const getRecipeEmoji = (title: string) => {
    const lowerTitle = title.toLowerCase()
    if (lowerTitle.includes('ポトフ')) return '🍲'
    if (lowerTitle.includes('オムレツ')) return '🍳'
    if (lowerTitle.includes('グラタン')) return '🧀'
    if (lowerTitle.includes('サラダ')) return '🥗'
    if (lowerTitle.includes('カレー')) return '🍛'
    if (lowerTitle.includes('パスタ')) return '🍝'
    if (lowerTitle.includes('ラーメン')) return '🍜'
    if (lowerTitle.includes('寿司')) return '🍣'
    if (lowerTitle.includes('ハンバーグ')) return '🍖'
    return '🍽️'
  }

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between">
        <div className="flex items-start gap-4 flex-1">
          {/* 絵文字アイコン */}
          <div className="flex-shrink-0">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center text-2xl">
              {getRecipeEmoji(history.recipe?.title || '')}
            </div>
          </div>

          {/* レシピ情報 */}
          <div className="flex-1">
            <div className="mb-2">
              <p className="text-sm text-gray-600 mb-1">
                {formatDate(history.cooked_at)}
              </p>
              <h3 className="text-lg font-bold text-gray-900 mb-2">
                {history.recipe?.title || 'レシピ名不明'}
              </h3>

              {/* レシピ詳細情報 */}
              <div className="flex items-center gap-4 text-sm text-gray-600">
                {/* 調理時間 */}
                {history.recipe?.cooking_time && (
                  <div className="flex items-center gap-1">
                    <FaClock className="w-4 h-4" />
                    <span>{history.recipe.cooking_time}分</span>
                  </div>
                )}
                {/* 難易度 */}
                {history.recipe?.difficulty && (
                  <div className="flex items-center gap-1">
                    <span>難易度: {history.recipe.difficulty}</span>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* 右側のアクション */}
        <div className="flex items-center gap-2">
          <button
            onClick={onClick}
            className="bg-green-500 text-white px-4 py-2 rounded-lg hover:bg-green-600 transition-colors text-sm font-medium"
          >
            詳細を見る
          </button>
          {onDelete && (
            <button
              onClick={(e) => {
                e.stopPropagation()
                if (window.confirm('この調理記録を削除しますか？')) {
                  onDelete()
                }
              }}
              className="bg-red-500 text-white px-3 py-2 rounded-lg hover:bg-red-600 transition-colors text-sm font-medium"
            >
              削除
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

export default RecipeHistoryItem
