import { apiClient } from './client'
import type {
  UserIngredientListResponse,
  UserIngredientGroupedResponse,
  UserIngredientSingleResponse,
} from '../types/ingredient'

// 食材一覧取得（group_by オプション対応）
export async function getUserIngredients(): Promise<UserIngredientListResponse>
export async function getUserIngredients(groupBy: 'category'): Promise<UserIngredientGroupedResponse>
export async function getUserIngredients(
  groupBy?: 'category'
): Promise<UserIngredientListResponse | UserIngredientGroupedResponse> {
  const params = groupBy ? { group_by: groupBy } : undefined
  const res = await apiClient.get('/user_ingredients', { params })
  return res.data
}

// 食材更新（PUTメソッド）
export async function updateUserIngredient(
  id: number,
  data: { quantity?: number; expiry_date?: string | null }
): Promise<UserIngredientSingleResponse> {
  const res = await apiClient.put(`/user_ingredients/${id}`, {
    user_ingredient: data,
  })
  return res.data
}

// 食材削除（204 No Content）
export async function deleteUserIngredient(id: number): Promise<void> {
  await apiClient.delete(`/user_ingredients/${id}`)
}

