import { apiClient } from './client'
import type {
  UserIngredientListResponse,
  UserIngredientSingleResponse,
  UserIngredientGroupedResponse,
  UserIngredientCreateData,
  UserIngredientUpdateData,
} from '../types/ingredient'

// 一覧取得（group_by対応）
export async function getUserIngredients(): Promise<UserIngredientListResponse>
export async function getUserIngredients(groupBy: 'category'): Promise<UserIngredientGroupedResponse>
export async function getUserIngredients(
  groupBy?: 'category'
): Promise<UserIngredientListResponse | UserIngredientGroupedResponse> {
  const params = groupBy ? { group_by: groupBy } : undefined
  const res = await apiClient.get('/user_ingredients', { params })
  return res.data
}

// 作成（POST）
export async function createUserIngredient(data: UserIngredientCreateData): Promise<UserIngredientSingleResponse> {
  const res = await apiClient.post('/user_ingredients', {
    user_ingredient: data,
  })
  return res.data
}

// 更新（PUT）
export async function updateUserIngredient(id: number, data: UserIngredientUpdateData): Promise<UserIngredientSingleResponse> {
  const res = await apiClient.put(`/user_ingredients/${id}`, {
    user_ingredient: data,
  })
  return res.data
}

// 削除
export async function deleteUserIngredient(id: number): Promise<void> {
  await apiClient.delete(`/user_ingredients/${id}`)
}

