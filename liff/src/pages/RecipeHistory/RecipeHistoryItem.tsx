import React from 'react'
import { formatDistanceToNow } from 'date-fns'
import { ja } from 'date-fns/locale'
import type { RecipeHistory } from '../../types/recipe'

interface RecipeHistoryItemProps {
  history: RecipeHistory
  onClick: () => void
}

const RecipeHistoryItem: React.FC<RecipeHistoryItemProps> = ({ history, onClick }) => {
  const formatRelativeTime = (dateString: string) => {
    try {
      const date = new Date(dateString)
      return formatDistanceToNow(date, { addSuffix: true, locale: ja })
    } catch {
      return '日時不明'
    }
  }

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, index) => (
      <span
        key={index}
        className={`text-sm ${
          index < rating ? 'text-yellow-500' : 'text-gray-300'
        }`}
      >
        ★
      </span>
    ))
  }

  return (
    <div
      onClick={onClick}
      className="bg-white rounded-lg shadow-md p-4 hover:shadow-lg transition-shadow cursor-pointer"
    >
      <div className="flex justify-between items-start mb-2">
        <div className="flex-1">
          <h2 className="text-lg font-semibold text-gray-800 line-clamp-2">
            {history.recipe?.title || 'レシピ名不明'}
          </h2>
          <p className="text-sm text-gray-500 mt-1">
            {formatRelativeTime(history.cooked_at)}
          </p>
        </div>
        <div className="ml-4 flex flex-col items-end space-y-1">
          {history.rating && (
            <div className="flex">
              {renderStars(history.rating)}
            </div>
          )}
          <button className="text-blue-500 hover:text-blue-700 text-sm whitespace-nowrap">
            詳細 →
          </button>
        </div>
      </div>
      
      {history.memo && (
        <div className="mt-3 p-3 bg-gray-50 rounded-lg">
          <p className="text-sm text-gray-700 line-clamp-2">
            <strong>メモ:</strong> {history.memo}
          </p>
        </div>
      )}
      
      {history.recipe && (
        <div className="mt-3 flex items-center space-x-4 text-xs text-gray-500">
          {history.recipe.cooking_time && (
            <span>⏱ {history.recipe.cooking_time}分</span>
          )}
          {history.recipe.difficulty && (
            <span>難易度: {history.recipe.difficulty}</span>
          )}
        </div>
      )}
    </div>
  )
}

export default RecipeHistoryItem