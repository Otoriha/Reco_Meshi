import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { recipesApi } from '../../api/recipes'
import type { Recipe } from '../../types/recipe'

const RecipeList: React.FC = () => {
  const [recipes, setRecipes] = useState<Recipe[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchRecipes = async () => {
      try {
        setLoading(true)
        const data = await recipesApi.listRecipes()
        setRecipes(data)
        setError(null)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'レシピの取得に失敗しました')
      } finally {
        setLoading(false)
      }
    }

    fetchRecipes()
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 p-6">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-center items-center h-64">
            <div className="text-gray-600">読み込み中...</div>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 p-6">
        <div className="max-w-7xl mx-auto">
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-red-700">{error}</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">レシピ一覧</h1>
        
        {recipes.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-6 text-center">
            <p className="text-gray-600">レシピが見つかりません</p>
            <p className="text-sm text-gray-500 mt-2">
              LINEで食材の写真を送信してレシピを作成してみてください
            </p>
          </div>
        ) : (
          <div className="grid gap-4">
            {recipes.map((recipe) => (
              <Link
                key={recipe.id}
                to={`/recipes/${recipe.id}`}
                className="block bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow p-6"
              >
                <div className="flex justify-between items-start mb-2">
                  <h2 className="text-xl font-semibold text-gray-800 line-clamp-2">
                    {recipe.title}
                  </h2>
                  <span className="text-sm text-gray-500 whitespace-nowrap ml-2">
                    {new Date(recipe.created_at).toLocaleDateString('ja-JP', {
                      month: 'short',
                      day: 'numeric'
                    })}
                  </span>
                </div>
                
                <div className="flex items-center justify-between text-sm text-gray-600">
                  <div className="flex items-center space-x-4">
                    <span className="flex items-center">
                      ⏱ {recipe.formatted_cooking_time}
                    </span>
                    <span className="flex items-center">
                      {recipe.difficulty_display}
                    </span>
                    {recipe.servings && (
                      <span className="flex items-center">
                        👥 {recipe.servings}人分
                      </span>
                    )}
                  </div>
                  <span className="text-blue-500">
                    詳細を見る →
                  </span>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default RecipeList