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
  rating?: number | null
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
  rating?: number | null
  cooked_at?: string
}

export interface UpdateRecipeHistoryParams {
  rating?: number | null
  memo?: string | null
}

// ページネーション用メタ情報
export interface PaginationMeta {
  current_page: number
  per_page: number
  total_pages: number
  total_count: number
}

// レシピ履歴検索パラメータ
export interface RecipeHistoriesParams {
  page?: number
  per_page?: number
  start_date?: string
  end_date?: string
  recipe_id?: number
  rated_only?: boolean
}

// チェックボックス用のローカル状態
export type IngredientCheckState = Record<number, boolean>