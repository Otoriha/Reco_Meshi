import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { recipesApi } from '../../api/recipes'
import type { RecipeHistory as RecipeHistoryType } from '../../types/recipe'

const RecipeHistory: React.FC = () => {
  const [histories, setHistories] = useState<RecipeHistoryType[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchHistories = async () => {
      try {
        setLoading(true)
        const data = await recipesApi.listRecipeHistories()
        setHistories(data)
        setError(null)
      } catch (err) {
        setError(err instanceof Error ? err.message : '調理履歴の取得に失敗しました')
      } finally {
        setLoading(false)
      }
    }

    fetchHistories()
  }, [])

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('ja-JP', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">レシピ履歴</h1>
        <div className="flex justify-center items-center min-h-64">
          <div className="text-gray-600">読み込み中...</div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">レシピ履歴</h1>
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-700">{error}</p>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">レシピ履歴</h1>
      
      {histories.length === 0 ? (
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-8 text-center">
          <p className="text-gray-600">調理履歴がありません</p>
          <p className="text-sm text-gray-500 mt-2">
            レシピを作って「作った！」ボタンを押すと履歴が記録されます
          </p>
          <Link
            to="/recipes"
            className="inline-block mt-4 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg transition-colors"
          >
            レシピを見る
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {histories.map((history) => (
            <div
              key={history.id}
              className="bg-white rounded-lg shadow-md p-4 hover:shadow-lg transition-shadow"
            >
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1">
                  <h2 className="text-lg font-semibold text-gray-800">
                    {history.recipe?.title || 'レシピ名不明'}
                  </h2>
                  <p className="text-sm text-gray-500">
                    調理日時: {formatDate(history.cooked_at)}
                  </p>
                </div>
                <Link
                  to={`/recipes/${history.recipe_id}`}
                  className="text-blue-500 hover:text-blue-700 text-sm whitespace-nowrap ml-4"
                >
                  レシピを見る →
                </Link>
              </div>
              
              {history.memo && (
                <div className="mt-3 p-3 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-700">
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
          ))}
        </div>
      )}
    </div>
  )
}

export default RecipeHistory