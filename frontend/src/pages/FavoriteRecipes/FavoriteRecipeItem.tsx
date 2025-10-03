import React from 'react'
import type { FavoriteRecipe } from '../../types/recipe'
import { FaClock } from 'react-icons/fa'
import FavoriteButton from '../../components/recipes/FavoriteButton'

interface FavoriteRecipeItemProps {
  favorite: FavoriteRecipe
  onClick: () => void
  onFavoriteToggle: () => void
}

const FavoriteRecipeItem: React.FC<FavoriteRecipeItemProps> = ({
  favorite,
  onClick,
  onFavoriteToggle
}) => {
  const formatDate = (dateString: string) => {
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('ja-JP', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        weekday: 'short'
      })
    } catch {
      return '日時不明'
    }
  }

  const getDifficultyDisplayName = (difficulty: string | null) => {
    if (!difficulty) return '指定なし'
    switch (difficulty) {
      case 'easy':
        return '簡単'
      case 'medium':
        return '普通'
      case 'hard':
        return '難しい'
      default:
        return difficulty
    }
  }

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
          <div className="flex-shrink-0">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center text-2xl">
              {getRecipeEmoji(favorite.recipe?.title || '')}
            </div>
          </div>

          <div className="flex-1">
            <div className="mb-2">
              <p className="text-sm text-gray-600 mb-1">
                お気に入り追加: {formatDate(favorite.created_at)}
              </p>
              <h3 className="text-lg font-bold text-gray-900 mb-2">
                {favorite.recipe?.title || 'レシピ名不明'}
              </h3>

              {favorite.recipe && (
                <div className="flex items-center gap-4 text-sm text-gray-600">
                  {favorite.recipe.cooking_time && (
                    <div className="flex items-center gap-1">
                      <FaClock className="w-4 h-4" />
                      <span>{favorite.recipe.cooking_time}分</span>
                    </div>
                  )}
                  {favorite.recipe.difficulty && (
                    <div className="flex items-center gap-1">
                      <span>難易度: {getDifficultyDisplayName(favorite.recipe.difficulty)}</span>
                    </div>
                  )}
                  {favorite.recipe.servings && (
                    <div className="flex items-center gap-1">
                      <span>{favorite.recipe.servings}人分</span>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <FavoriteButton
            recipeId={favorite.recipe_id}
            favoriteId={favorite.id}
            onToggle={onFavoriteToggle}
            compact
          />
          <button
            onClick={onClick}
            className="bg-green-500 text-white px-4 py-2 rounded-lg hover:bg-green-600 transition-colors text-sm font-medium"
          >
            詳細を見る
          </button>
        </div>
      </div>
    </div>
  )
}

export default FavoriteRecipeItem
