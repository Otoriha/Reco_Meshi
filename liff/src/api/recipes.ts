import { apiClient } from './client'
import type { Recipe, RecipeHistory, CreateRecipeHistoryParams } from '../types/recipe'

interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
  errors?: string[]
}

export const recipesApi = {
  // レシピ一覧取得
  async listRecipes(): Promise<Recipe[]> {
    const response = await apiClient.get<ApiResponse<Recipe[]>>('/recipes')
    if (!response.data.success) {
      throw new Error('レシピ一覧の取得に失敗しました')
    }
    return response.data.data
  },

  // レシピ詳細取得
  async getRecipe(id: number): Promise<Recipe> {
    const response = await apiClient.get<ApiResponse<Recipe>>(`/recipes/${id}`)
    if (!response.data.success) {
      throw new Error('レシピ詳細の取得に失敗しました')
    }
    return response.data.data
  },

  // 調理履歴一覧取得
  async listRecipeHistories(): Promise<RecipeHistory[]> {
    const response = await apiClient.get<ApiResponse<RecipeHistory[]>>('/recipe_histories')
    if (!response.data.success) {
      throw new Error('調理履歴の取得に失敗しました')
    }
    return response.data.data
  },

  // 調理履歴作成
  async createRecipeHistory(params: CreateRecipeHistoryParams): Promise<RecipeHistory> {
    const response = await apiClient.post<ApiResponse<RecipeHistory>>(
      '/recipe_histories',
      { recipe_history: params }
    )
    if (!response.data.success) {
      throw new Error(response.data.message || '調理記録の保存に失敗しました')
    }
    return response.data.data
  }
}