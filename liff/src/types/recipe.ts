export interface Recipe {
  id: number
  title: string
  cooking_time: number
  formatted_cooking_time: string
  difficulty: 'easy' | 'medium' | 'hard' | null
  difficulty_display: string
  servings: number | null
  created_at: string
  steps?: string[]
  ingredients?: RecipeIngredient[]
}

export interface RecipeIngredient {
  id: number
  name: string
  amount: number | null
  unit: string | null
  is_optional: boolean
}

export interface RecipeHistory {
  id: number
  user_id: number
  recipe_id: number
  cooked_at: string
  memo: string | null
  created_at: string
  updated_at: string
  recipe?: {
    id: number
    title: string
    cooking_time: number
    difficulty: string | null
  }
}

export interface CreateRecipeHistoryParams {
  recipe_id: number
  memo?: string
  cooked_at?: string
}

// チェックボックス用のローカル状態
export interface IngredientCheckState {
  [ingredientId: number]: boolean
}