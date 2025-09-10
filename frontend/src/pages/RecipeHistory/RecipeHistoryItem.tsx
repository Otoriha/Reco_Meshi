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
        className={`text-lg ${
          index < rating ? 'text-yellow-400' : 'text-gray-300'
        }`}
      >
        ★
      </span>
    ))
  }

  return (
    <div
      onClick={onClick}
      className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow cursor-pointer border border-gray-100"
    >
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h2 className="text-xl font-semibold text-gray-800 line-clamp-2 mb-2">
            {history.recipe?.title || 'レシピ名不明'}
          </h2>
          <p className="text-sm text-gray-500">
            {formatRelativeTime(history.cooked_at)}
          </p>
        </div>
        <div className="ml-6 flex flex-col items-end space-y-2">
          {history.rating && (
            <div className="flex">
              {renderStars(history.rating)}
            </div>
          )}
          <button className="text-blue-600 hover:text-blue-800 text-sm font-medium whitespace-nowrap">
            詳細を見る →
          </button>
        </div>
      </div>
      
      {history.memo && (
        <div className="mt-4 p-4 bg-gray-50 rounded-lg">
          <p className="text-sm text-gray-700 line-clamp-3">
            <strong className="text-gray-800">メモ:</strong> {history.memo}
          </p>
        </div>
      )}
      
      {history.recipe && (
        <div className="mt-4 flex items-center space-x-6 text-sm text-gray-500">
          {history.recipe.cooking_time && (
            <span className="flex items-center">
              <span className="mr-1">⏱</span>
              {history.recipe.cooking_time}分
            </span>
          )}
          {history.recipe.difficulty && (
            <span className="flex items-center">
              難易度: {history.recipe.difficulty}
            </span>
          )}
        </div>
      )}
    </div>
  )
}

export default RecipeHistoryItem