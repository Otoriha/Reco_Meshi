import { apiClient } from './client'
import type { IngredientListResponse } from '../types/ingredient'

type GetIngredientsParams = {
  page?: number
  per_page?: number
  search?: string
  category?: string
}

// 食材マスタ一覧（ページング/検索）
export async function getIngredients(params: GetIngredientsParams = {}): Promise<IngredientListResponse> {
  const res = await apiClient.get<IngredientListResponse>('/ingredients', { params });
  return res.data;
}

