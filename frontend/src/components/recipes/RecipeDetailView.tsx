import React, { useState } from 'react'
import type { Recipe, IngredientCheckState } from '../../types/recipe'
import { FaClock, FaUtensils, FaCheck } from 'react-icons/fa'

interface RecipeDetailViewProps {
  recipe: Recipe
  onSaveToHistory?: () => void
  showSaveButton?: boolean
}

const RecipeDetailView: React.FC<RecipeDetailViewProps> = ({
  recipe,
  onSaveToHistory,
  showSaveButton = true
}) => {
  const [checkedIngredients, setCheckedIngredients] = useState<IngredientCheckState>({})

  const handleIngredientCheck = (ingredientId: number) => {
    setCheckedIngredients(prev => ({
      ...prev,
      [ingredientId]: !prev[ingredientId]
    }))
  }

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'かんたん':
        return 'text-green-600 bg-green-100'
      case 'medium':
      case 'ふつう':
        return 'text-yellow-600 bg-yellow-100'
      case 'hard':
      case 'むずかしい':
        return 'text-red-600 bg-red-100'
      default:
        return 'text-gray-600 bg-gray-100'
    }
  }

  return (
    <div className="space-y-6">
      {/* レシピヘッダー */}
      <div className="text-center border-b pb-4">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">{recipe.title}</h2>
        <div className="flex justify-center items-center space-x-4 text-sm text-gray-600">
          <div className="flex items-center">
            <FaClock className="mr-1" />
            <span>{recipe.formatted_cooking_time}</span>
          </div>
          <div className="flex items-center">
            <FaUtensils className="mr-1" />
            <span>{recipe.servings}人分</span>
          </div>
          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getDifficultyColor(recipe.difficulty_display)}`}>
            {recipe.difficulty_display}
          </span>
        </div>
      </div>

      {/* 材料リスト */}
      {recipe.ingredients && recipe.ingredients.length > 0 && (
        <div>
          <h3 className="text-lg font-semibold text-gray-900 mb-3">材料</h3>
          <div className="bg-gray-50 rounded-lg p-4">
            <div className="space-y-2">
              {recipe.ingredients.map((ingredient) => (
                <label
                  key={ingredient.id}
                  className="flex items-center space-x-3 cursor-pointer hover:bg-gray-100 p-2 rounded"
                >
                  <input
                    type="checkbox"
                    checked={checkedIngredients[ingredient.id] || false}
                    onChange={() => handleIngredientCheck(ingredient.id)}
                    className="h-4 w-4 text-pink-600 focus:ring-pink-500 border-gray-300 rounded"
                  />
                  <div className="flex-1 flex justify-between items-center">
                    <span className={`text-sm ${checkedIngredients[ingredient.id] ? 'line-through text-gray-500' : 'text-gray-900'}`}>
                      {ingredient.name}
                      {ingredient.is_optional && (
                        <span className="text-xs text-gray-500 ml-1">(お好みで)</span>
                      )}
                    </span>
                    <span className={`text-sm font-medium ${checkedIngredients[ingredient.id] ? 'line-through text-gray-500' : 'text-gray-600'}`}>
                      {ingredient.amount && ingredient.unit
                        ? `${ingredient.amount}${ingredient.unit}`
                        : ingredient.amount
                        ? ingredient.amount
                        : ingredient.unit || '適量'
                      }
                    </span>
                  </div>
                  {checkedIngredients[ingredient.id] && (
                    <FaCheck className="text-green-500" />
                  )}
                </label>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 調理手順 */}
      {recipe.steps && recipe.steps.length > 0 && (
        <div>
          <h3 className="text-lg font-semibold text-gray-900 mb-3">調理手順</h3>
          <div className="space-y-3">
            {recipe.steps.map((step, index) => (
              <div key={index} className="flex items-start space-x-3">
                <div className="flex-shrink-0 w-6 h-6 bg-pink-500 text-white rounded-full flex items-center justify-center text-sm font-medium">
                  {index + 1}
                </div>
                <p className="text-gray-700 leading-relaxed">{step}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 保存ボタン */}
      {showSaveButton && onSaveToHistory && (
        <div className="pt-4 border-t">
          <button
            onClick={onSaveToHistory}
            className="w-full bg-pink-500 text-white py-2 px-4 rounded-md hover:bg-pink-600 transition-colors font-medium flex items-center justify-center"
          >
            <FaCheck className="mr-2" />
            レシピを保存
          </button>
          <p className="text-xs text-gray-500 text-center mt-2">
            作ったレシピをあとで確認できます
          </p>
        </div>
      )}
    </div>
  )
}

export default RecipeDetailView