import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { recipesApi } from '../../api/recipes'
import type { Recipe, IngredientCheckState } from '../../types/recipe'

const RecipeDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [recipe, setRecipe] = useState<Recipe | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [checkedIngredients, setCheckedIngredients] = useState<IngredientCheckState>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [memo, setMemo] = useState('')

  useEffect(() => {
    const fetchRecipe = async () => {
      if (!id) return
      
      try {
        setLoading(true)
        const data = await recipesApi.getRecipe(parseInt(id, 10))
        setRecipe(data)
        setError(null)
        
        // 初期状態では全ての材料のチェックを外す
        if (data.ingredients) {
          const initialChecked: IngredientCheckState = {}
          data.ingredients.forEach(ingredient => {
            initialChecked[ingredient.id] = false
          })
          setCheckedIngredients(initialChecked)
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'レシピの取得に失敗しました')
      } finally {
        setLoading(false)
      }
    }

    fetchRecipe()
  }, [id])

  const handleIngredientCheck = (ingredientId: number) => {
    setCheckedIngredients(prev => ({
      ...prev,
      [ingredientId]: !prev[ingredientId]
    }))
  }

  const handleCookedSubmit = async () => {
    if (!recipe) return
    
    try {
      setIsSubmitting(true)
      
      await recipesApi.createRecipeHistory({
        recipe_id: recipe.id,
        memo: memo.trim() || undefined
      })
      
      // 成功した場合、履歴ページに遷移
      alert('調理記録を保存しました！')
      navigate('/recipe-history')
    } catch (err) {
      alert(err instanceof Error ? err.message : '調理記録の保存に失敗しました')
    } finally {
      setIsSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 p-6">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-center items-center min-h-64">
            <div className="text-gray-600">読み込み中...</div>
          </div>
        </div>
      </div>
    )
  }

  if (error || !recipe) {
    return (
      <div className="min-h-screen bg-gray-50 p-6">
        <div className="max-w-7xl mx-auto">
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-red-700">{error || 'レシピが見つかりません'}</p>
          </div>
          <button
            onClick={() => navigate('/recipes')}
            className="mt-4 text-blue-500 hover:text-blue-700"
          >
            ← レシピ一覧に戻る
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-4xl mx-auto">
        {/* ヘッダー */}
        <div className="mb-6">
          <button
            onClick={() => navigate('/recipes')}
            className="text-blue-500 hover:text-blue-700 mb-2"
          >
            ← レシピ一覧に戻る
          </button>
          <h1 className="text-3xl font-bold text-gray-900">{recipe.title}</h1>
        </div>

        {/* レシピ基本情報 */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <div className="grid grid-cols-2 gap-4 mb-4">
            <div className="text-center">
              <div className="text-sm text-gray-500">調理時間</div>
              <div className="text-lg font-semibold text-gray-800">
                ⏱ {recipe.formatted_cooking_time}
              </div>
            </div>
            <div className="text-center">
              <div className="text-sm text-gray-500">難易度</div>
              <div className="text-lg font-semibold text-gray-800">
                {recipe.difficulty_display}
              </div>
            </div>
          </div>
          {recipe.servings && (
            <div className="text-center">
              <div className="text-sm text-gray-500">人数</div>
              <div className="text-lg font-semibold text-gray-800">
                👥 {recipe.servings}人分
              </div>
            </div>
          )}
        </div>

        {/* 材料リスト */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">材料</h2>
          {recipe.ingredients && recipe.ingredients.length > 0 ? (
            <div className="space-y-3">
              {recipe.ingredients.map((ingredient) => (
                <label
                  key={ingredient.id}
                  className="flex items-center space-x-3 cursor-pointer hover:bg-gray-50 p-2 rounded"
                >
                  <input
                    type="checkbox"
                    checked={checkedIngredients[ingredient.id] || false}
                    onChange={() => handleIngredientCheck(ingredient.id)}
                    className="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500"
                  />
                  <div className="flex-1">
                    <span className={`${checkedIngredients[ingredient.id] ? 'line-through text-gray-500' : 'text-gray-800'}`}>
                      {ingredient.name}
                    </span>
                    {(ingredient.amount || ingredient.unit) && (
                      <span className="text-gray-600 ml-2">
                        {ingredient.amount && `${ingredient.amount}`}
                        {ingredient.unit && `${ingredient.unit}`}
                      </span>
                    )}
                    {ingredient.is_optional && (
                      <span className="text-sm text-gray-500 ml-2">(お好みで)</span>
                    )}
                  </div>
                </label>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">材料情報がありません</p>
          )}
        </div>

        {/* 調理手順 */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">調理手順</h2>
          {recipe.steps && recipe.steps.length > 0 ? (
            <ol className="space-y-4">
              {recipe.steps.map((step, index) => (
                <li key={index} className="flex">
                  <span className="bg-blue-500 text-white text-sm font-bold rounded-full w-8 h-8 flex items-center justify-center mr-3 mt-1 flex-shrink-0">
                    {index + 1}
                  </span>
                  <p className="text-gray-800 leading-relaxed">{step}</p>
                </li>
              ))}
            </ol>
          ) : (
            <p className="text-gray-500">調理手順がありません</p>
          )}
        </div>

        {/* メモ入力 */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">メモ（任意）</h2>
          <textarea
            value={memo}
            onChange={(e) => setMemo(e.target.value)}
            placeholder="作った感想や工夫した点などを記録できます"
            className="w-full p-3 border border-gray-300 rounded-lg resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            rows={3}
          />
        </div>

        {/* 作ったボタン */}
        <div className="sticky bottom-6">
          <button
            onClick={handleCookedSubmit}
            disabled={isSubmitting}
            className="w-full bg-green-500 hover:bg-green-600 disabled:bg-gray-300 text-white font-bold py-4 px-6 rounded-lg transition-colors shadow-lg"
          >
            {isSubmitting ? '保存中...' : '🍽 作った！'}
          </button>
        </div>
      </div>
    </div>
  )
}

export default RecipeDetail