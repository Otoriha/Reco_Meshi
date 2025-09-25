import React, { useState } from 'react'
import Modal from '../ui/Modal'
import type { Recipe } from '../../types/recipe'
import { recipesApi, type RecipeSuggestionRequest } from '../../api/recipes'
import RecipeDetailView from './RecipeDetailView'

interface RecipeSuggestModalProps {
  isOpen: boolean
  onClose: () => void
  onRecipeGenerated?: (recipe: Recipe) => void
}

const RecipeSuggestModal: React.FC<RecipeSuggestModalProps> = ({
  isOpen,
  onClose,
  onRecipeGenerated
}) => {
  const [currentStep, setCurrentStep] = useState<'preferences' | 'result'>('preferences')
  const [isGenerating, setIsGenerating] = useState(false)
  const [generatedRecipe, setGeneratedRecipe] = useState<Recipe | null>(null)
  const [error, setError] = useState<string | null>(null)

  // フォーム状態
  const [ingredients, setIngredients] = useState<string>('')
  const [preferences, setPreferences] = useState<RecipeSuggestionRequest['preferences']>({
    cooking_time: undefined,
    difficulty_level: undefined,
    cuisine_type: '',
    dietary_restrictions: []
  })

  const resetModal = () => {
    setCurrentStep('preferences')
    setGeneratedRecipe(null)
    setError(null)
    setIngredients('')
    setPreferences({
      cooking_time: undefined,
      difficulty_level: undefined,
      cuisine_type: '',
      dietary_restrictions: []
    })
  }

  const handleClose = () => {
    resetModal()
    onClose()
  }

  const handleGenerate = async () => {
    setIsGenerating(true)
    setError(null)

    try {
      // バリデーション
      if (preferences?.cooking_time && (preferences.cooking_time < 1 || preferences.cooking_time > 300)) {
        setError('調理時間は1分〜300分の間で入力してください')
        return
      }

      const requestParams: RecipeSuggestionRequest = {
        ...(ingredients.trim() && {
          ingredients: ingredients.split(',').map(item => item.trim()).filter(Boolean)
        }),
        preferences: {
          ...(preferences?.cooking_time && { cooking_time: preferences.cooking_time }),
          ...(preferences?.difficulty_level && { difficulty_level: preferences.difficulty_level }),
          ...(preferences?.cuisine_type?.trim() && { cuisine_type: preferences.cuisine_type.trim() }),
          ...(preferences?.dietary_restrictions?.length && { dietary_restrictions: preferences.dietary_restrictions })
        }
      }

      const recipe = await recipesApi.suggestRecipe(requestParams)
      setGeneratedRecipe(recipe)
      setCurrentStep('result')
      onRecipeGenerated?.(recipe)
    } catch (err) {
      let errorMessage = 'レシピ生成に失敗しました'

      if (err instanceof Error) {
        if (err.message.includes('401')) {
          errorMessage = 'ログインが必要です。再度ログインしてください。'
        } else if (err.message.includes('422')) {
          errorMessage = err.message || '入力内容に問題があります。設定を確認してください。'
        } else if (err.message.includes('500')) {
          errorMessage = 'サーバーエラーが発生しました。しばらくしてから再度お試しください。'
        } else if (err.message.includes('Network')) {
          errorMessage = 'ネットワークエラーが発生しました。通信環境を確認してください。'
        } else {
          errorMessage = err.message
        }
      }

      setError(errorMessage)
    } finally {
      setIsGenerating(false)
    }
  }

  const handleDietaryRestrictionChange = (restriction: string, checked: boolean) => {
    setPreferences((prev: RecipeSuggestionRequest['preferences']) => ({
      ...prev,
      dietary_restrictions: checked
        ? [...(prev?.dietary_restrictions || []), restriction]
        : (prev?.dietary_restrictions || []).filter((item: string) => item !== restriction)
    }))
  }

  const renderPreferencesForm = () => (
    <div className="space-y-6 max-w-md mx-auto">
      {/* 食材指定 */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          使いたい食材（任意）
        </label>
        <textarea
          value={ingredients}
          onChange={(e) => setIngredients(e.target.value)}
          placeholder="例: 玉ねぎ, 豚肉, 人参（カンマ区切りで入力）"
          className="w-full px-3 py-2 border border-pink-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-pink-500"
          rows={2}
        />
        <p className="text-xs text-gray-500 mt-1">
          空欄の場合、在庫食材から自動で選択されます
        </p>
      </div>

      {/* 調理時間 */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          調理時間（分）
        </label>
        <input
          type="number"
          value={preferences?.cooking_time || ''}
          onChange={(e) => setPreferences((prev: RecipeSuggestionRequest['preferences']) => ({
            ...prev,
            cooking_time: e.target.value ? parseInt(e.target.value) : undefined
          }))}
          placeholder="例: 30"
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
          min="1"
          max="300"
        />
      </div>

      {/* 難易度 */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          難易度
        </label>
        <select
          value={preferences?.difficulty_level || ''}
          onChange={(e) => setPreferences((prev: RecipeSuggestionRequest['preferences']) => ({
            ...prev,
            difficulty_level: e.target.value as 'easy' | 'medium' | 'hard' | undefined
          }))}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
        >
          <option value="">選択してください</option>
          <option value="easy">かんたん</option>
          <option value="medium">ふつう</option>
          <option value="hard">むずかしい</option>
        </select>
      </div>

      {/* 料理ジャンル */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          料理ジャンル
        </label>
        <input
          type="text"
          value={preferences?.cuisine_type || ''}
          onChange={(e) => setPreferences((prev: RecipeSuggestionRequest['preferences']) => ({
            ...prev,
            cuisine_type: e.target.value
          }))}
          placeholder="例: 和食, 中華, イタリアン"
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
        />
      </div>

      {/* 食事制限 */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          食事制限
        </label>
        <div className="space-y-2">
          {['ベジタリアン', 'ヴィーガン', '糖質制限', '塩分制限', 'グルテンフリー'].map(restriction => (
            <label key={restriction} className="flex items-center">
              <input
                type="checkbox"
                checked={preferences?.dietary_restrictions?.includes(restriction) || false}
                onChange={(e) => handleDietaryRestrictionChange(restriction, e.target.checked)}
                className="mr-2 h-4 w-4 text-pink-600 focus:ring-pink-500 border-gray-300 rounded"
              />
              <span className="text-sm text-gray-700">{restriction}</span>
            </label>
          ))}
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-md p-3">
          <p className="text-red-600 text-sm">{error}</p>
        </div>
      )}

      <div className="flex justify-end space-x-3">
        <button
          onClick={handleClose}
          className="px-4 py-2 text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50"
          disabled={isGenerating}
        >
          キャンセル
        </button>
        <button
          onClick={handleGenerate}
          className="px-4 py-2 bg-pink-500 text-white rounded-md hover:bg-pink-600 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
          disabled={isGenerating}
        >
          {isGenerating ? (
            <>
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
              レシピ生成中...
            </>
          ) : (
            'レシピを生成'
          )}
        </button>
      </div>
    </div>
  )

  const renderResult = () => (
    <div>
      {generatedRecipe && (
        <RecipeDetailView
          recipe={generatedRecipe}
          onSaveToHistory={async () => {
            if (!generatedRecipe) return
            try {
              await recipesApi.createRecipeHistory({
                recipe_id: generatedRecipe.id,
                memo: `${generatedRecipe.title}を作りました`,
                cooked_at: new Date().toISOString()
              })
              // 成功時は親コンポーネントに通知
              onRecipeGenerated?.(generatedRecipe)
            } catch (error) {
              console.error('レシピ保存エラー:', error)
              setError('レシピの保存に失敗しました')
            }
          }}
          onShoppingListCreated={(message) => {
            // 買い物リスト作成成功/エラー時の処理
            setError(message.includes('エラー') ? message : null)
            // 成功時は親に通知
            if (!message.includes('エラー')) {
              onRecipeGenerated?.(generatedRecipe)
            }
          }}
        />
      )}
      <div className="flex justify-end space-x-3 mt-6 pt-4 border-t">
        <button
          onClick={() => setCurrentStep('preferences')}
          className="px-4 py-2 text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50"
        >
          再生成
        </button>
        <button
          onClick={handleClose}
          className="px-4 py-2 bg-pink-500 text-white rounded-md hover:bg-pink-600"
        >
          閉じる
        </button>
      </div>
    </div>
  )

  return (
    <Modal
      isOpen={isOpen}
      onClose={handleClose}
      title={currentStep === 'preferences' ? 'レシピ提案設定' : '生成されたレシピ'}
      size={currentStep === 'result' ? 'lg' : 'md'}
    >
      <div className={`${currentStep === 'result' ? 'max-h-[80vh]' : 'max-h-96'} overflow-y-auto`}>
        {currentStep === 'preferences' ? renderPreferencesForm() : renderResult()}
      </div>
    </Modal>
  )
}

export default RecipeSuggestModal