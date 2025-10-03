import React, { useState } from 'react'
import { FaHeart, FaRegHeart } from 'react-icons/fa'
import { useToast } from '../../hooks/useToast'

interface FavoriteButtonProps {
  recipeId: number
  favoriteId: number | null
  onToggle?: (isFavorited: boolean) => void
  compact?: boolean
}

const FavoriteButton: React.FC<FavoriteButtonProps> = ({
  recipeId,
  favoriteId,
  onToggle,
  compact = false
}) => {
  const [isLoading, setIsLoading] = useState(false)
  const { showSuccess, showError } = useToast()
  const isFavorited = favoriteId !== null

  const handleClick = async (e: React.MouseEvent) => {
    e.stopPropagation()
    e.preventDefault()

    if (isLoading) return

    setIsLoading(true)
    try {
      if (isFavorited && favoriteId !== null) {
        const { recipesApi } = await import('../../api/recipes')
        await recipesApi.removeFavoriteRecipe(favoriteId)
        showSuccess('お気に入りから削除しました')
        onToggle?.(false)
      } else {
        const { recipesApi } = await import('../../api/recipes')
        await recipesApi.addFavoriteRecipe({ recipe_id: recipeId })
        showSuccess('お気に入りに追加しました')
        onToggle?.(true)
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'エラーが発生しました'
      showError(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  if (compact) {
    return (
      <button
        onClick={handleClick}
        disabled={isLoading}
        className={`p-2 rounded-full transition-colors ${
          isLoading
            ? 'opacity-50 cursor-not-allowed'
            : 'hover:bg-gray-100'
        }`}
        title={isFavorited ? 'お気に入りから削除' : 'お気に入りに追加'}
      >
        {isFavorited ? (
          <FaHeart className="w-5 h-5 text-pink-500" />
        ) : (
          <FaRegHeart className="w-5 h-5 text-gray-400" />
        )}
      </button>
    )
  }

  return (
    <button
      onClick={handleClick}
      disabled={isLoading}
      className={`flex items-center gap-2 px-4 py-2 rounded-lg border transition-colors ${
        isFavorited
          ? 'border-pink-500 bg-pink-50 text-pink-600 hover:bg-pink-100'
          : 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50'
      } ${
        isLoading ? 'opacity-50 cursor-not-allowed' : ''
      }`}
    >
      {isLoading ? (
        <>
          <div className="w-5 h-5 border-2 border-gray-300 border-t-transparent rounded-full animate-spin"></div>
          <span className="text-sm font-medium">処理中...</span>
        </>
      ) : (
        <>
          {isFavorited ? (
            <>
              <FaHeart className="w-5 h-5" />
              <span className="text-sm font-medium">お気に入り済み</span>
            </>
          ) : (
            <>
              <FaRegHeart className="w-5 h-5" />
              <span className="text-sm font-medium">お気に入りに追加</span>
            </>
          )}
        </>
      )}
    </button>
  )
}

export default FavoriteButton
