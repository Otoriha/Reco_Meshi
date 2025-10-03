import { apiClient } from './client'
import type { Recipe, RecipeHistory, CreateRecipeHistoryParams, UpdateRecipeHistoryParams, PaginationMeta, RecipeHistoriesParams, FavoriteRecipe, FavoriteRecipesParams, CreateFavoriteRecipeParams, UpdateFavoriteRecipeParams } from '../types/recipe'

export type { PaginationMeta, RecipeHistoriesParams, FavoriteRecipesParams, CreateFavoriteRecipeParams, UpdateFavoriteRecipeParams }

interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
  errors?: string[]
}

interface PaginatedApiResponse<T> {
  success: boolean
  data: T[]
  meta: PaginationMeta
  message?: string
  errors?: string[]
}

export interface RecipeSuggestionRequest {
  ingredients?: string[];
  preferences?: {
    cooking_time?: number;
    difficulty_level?: 'easy' | 'medium' | 'hard';
    cuisine_type?: string;
    dietary_restrictions?: string[];
  };
}

export interface RecipeSuggestionResponse {
  success: boolean;
  data: Recipe;
  message?: string;
  errors?: string[];
}

export const recipesApi = {
  // AIレシピ提案取得
  async suggestRecipe(params?: RecipeSuggestionRequest): Promise<Recipe> {
    const response = await apiClient.post<RecipeSuggestionResponse>(
      '/recipes/suggest',
      { recipe_suggestion: params }
    );
    if (!response.data.success) {
      throw new Error(response.data.message || 'レシピ提案の取得に失敗しました');
    }
    return response.data.data;
  },

  // レシピ一覧取得
  async listRecipes(): Promise<Recipe[]> {
    const response = await apiClient.get<ApiResponse<Recipe[]>>('/recipes')
    if (!response.data.success) {
      throw new Error(response.data.message || 'レシピ一覧の取得に失敗しました')
    }
    return response.data.data
  },

  // レシピ詳細取得
  async getRecipe(id: number): Promise<Recipe> {
    const response = await apiClient.get<ApiResponse<Recipe>>(`/recipes/${id}`)
    if (!response.data.success) {
      throw new Error(response.data.message || 'レシピ詳細の取得に失敗しました')
    }
    return response.data.data
  },

  // 調理履歴一覧取得（従来版 - 互換性のため残す）
  async listRecipeHistories(): Promise<RecipeHistory[]> {
    const result = await this.fetchRecipeHistories()
    return result.data
  },

  // 調理履歴一覧取得（メタ情報付き）
  async fetchRecipeHistories(params: RecipeHistoriesParams = {}): Promise<{ data: RecipeHistory[]; meta: PaginationMeta }> {
    const searchParams = new URLSearchParams()
    
    if (params.page) searchParams.append('page', params.page.toString())
    if (params.per_page) searchParams.append('per_page', params.per_page.toString())
    if (params.start_date) searchParams.append('start_date', params.start_date)
    if (params.end_date) searchParams.append('end_date', params.end_date)
    if (params.recipe_id) searchParams.append('recipe_id', params.recipe_id.toString())
    if (params.favorited_only !== undefined) searchParams.append('favorited_only', params.favorited_only.toString())

    const url = `/recipe_histories${searchParams.toString() ? `?${searchParams.toString()}` : ''}`
    const response = await apiClient.get<PaginatedApiResponse<RecipeHistory>>(url)
    
    if (!response.data.success) {
      throw new Error('調理履歴の取得に失敗しました')
    }
    
    return {
      data: response.data.data,
      meta: response.data.meta
    }
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
  },

  // 調理履歴更新
  async updateRecipeHistory(id: number, params: UpdateRecipeHistoryParams): Promise<RecipeHistory> {
    const response = await apiClient.patch<ApiResponse<RecipeHistory>>(
      `/recipe_histories/${id}`,
      { recipe_history: params }
    )
    if (!response.data.success) {
      throw new Error(response.data.message || '調理記録の更新に失敗しました')
    }
    return response.data.data
  },

  // 調理履歴削除
  async deleteRecipeHistory(id: number): Promise<void> {
    const response = await apiClient.delete<ApiResponse<never>>(`/recipe_histories/${id}`)
    if (!response.data.success) {
      throw new Error(response.data.message || '調理記録の削除に失敗しました')
    }
  },

  // お気に入り一覧取得（ページネーション対応）
  async fetchFavoriteRecipes(params: FavoriteRecipesParams = {}): Promise<{ data: FavoriteRecipe[]; meta: PaginationMeta }> {
    const searchParams = new URLSearchParams()

    if (params.page) searchParams.append('page', params.page.toString())
    if (params.per_page) searchParams.append('per_page', params.per_page.toString())

    const url = `/favorite_recipes${searchParams.toString() ? `?${searchParams.toString()}` : ''}`
    const response = await apiClient.get<PaginatedApiResponse<FavoriteRecipe>>(url)

    if (!response.data.success) {
      throw new Error(response.data.message || 'お気に入りの取得に失敗しました')
    }

    return {
      data: response.data.data,
      meta: response.data.meta
    }
  },

  // お気に入り追加
  async addFavoriteRecipe(params: CreateFavoriteRecipeParams): Promise<FavoriteRecipe> {
    const response = await apiClient.post<ApiResponse<FavoriteRecipe>>(
      '/favorite_recipes',
      { favorite_recipe: params }
    )
    if (!response.data.success) {
      throw new Error(response.data.message || 'お気に入りの追加に失敗しました')
    }
    return response.data.data
  },

  // お気に入り更新（評価の変更）
  async updateFavoriteRecipe(favoriteId: number, params: UpdateFavoriteRecipeParams): Promise<FavoriteRecipe> {
    const response = await apiClient.patch<ApiResponse<FavoriteRecipe>>(
      `/favorite_recipes/${favoriteId}`,
      { favorite_recipe: params }
    )
    if (!response.data.success) {
      throw new Error(response.data.message || '評価の更新に失敗しました')
    }
    return response.data.data
  },

  // お気に入り削除
  async removeFavoriteRecipe(favoriteId: number): Promise<void> {
    const response = await apiClient.delete<ApiResponse<never>>(`/favorite_recipes/${favoriteId}`)
    if (!response.data.success) {
      throw new Error(response.data.message || 'お気に入りの削除に失敗しました')
    }
  }
}