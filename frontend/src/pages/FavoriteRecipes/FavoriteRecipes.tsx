import React, { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useFavoriteRecipes } from '../../hooks/useFavoriteRecipes'
import FavoriteRecipeItem from './FavoriteRecipeItem'
import Pagination from '../../components/Pagination'
import Toast from '../../components/Toast'
import { useToast } from '../../hooks/useToast'
import type { FavoriteRecipe } from '../../types/recipe'

const FavoriteRecipes: React.FC = () => {
  const navigate = useNavigate()
  const {
    favorites,
    loading,
    error,
    initialized,
    fetchFavorites,
    refreshFavorites,
    currentPage,
    totalPages
  } = useFavoriteRecipes()

  const { toast, hideToast } = useToast()

  useEffect(() => {
    if (!initialized) {
      fetchFavorites()
    }
  }, [initialized, fetchFavorites])

  const handleItemClick = (favorite: FavoriteRecipe) => {
    if (favorite.recipe_id) {
      navigate(`/recipes/${favorite.recipe_id}`)
    }
  }

  const handleFavoriteToggle = async () => {
    await refreshFavorites()
  }

  const handlePageChange = async (page: number) => {
    await fetchFavorites({ page })
  }

  if (loading && favorites.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-8">お気に入りレシピ</h1>
          <div className="text-center py-8">
            <p className="text-gray-600">読み込み中...</p>
          </div>
        </div>
      </div>
    )
  }

  if (error && favorites.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-8">お気に入りレシピ</h1>
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <p className="text-red-700 text-center">{error}</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">お気に入りレシピ</h1>

        {favorites.length === 0 && !loading ? (
          <div className="bg-white rounded-lg shadow-sm p-12 text-center">
            <div className="text-6xl mb-6">💗</div>
            <h3 className="text-xl font-semibold text-gray-800 mb-4">
              お気に入りレシピがありません
            </h3>
            <p className="text-gray-600 mb-6">
              気になるレシピを見つけたら、お気に入りに追加してみましょう
            </p>
            <button
              onClick={() => navigate('/recipes')}
              className="inline-block bg-pink-500 hover:bg-pink-600 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
            >
              レシピを探す
            </button>
          </div>
        ) : (
          <>
            <div className="space-y-4">
              {favorites.map((favorite) => (
                <FavoriteRecipeItem
                  key={favorite.id}
                  favorite={favorite}
                  onClick={() => handleItemClick(favorite)}
                  onFavoriteToggle={handleFavoriteToggle}
                />
              ))}
            </div>

            <Pagination
              currentPage={currentPage}
              totalPages={totalPages}
              onPageChange={handlePageChange}
              loading={loading}
            />
          </>
        )}
      </div>

      <Toast
        message={toast.message}
        type={toast.type}
        isVisible={toast.isVisible}
        onClose={hideToast}
      />
    </div>
  )
}

export default FavoriteRecipes
