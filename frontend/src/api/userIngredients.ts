import { apiClient } from './client'
import type {
  UserIngredientListResponse,
  UserIngredientSingleResponse,
  UserIngredientGroupedResponse,
  UserIngredientCreateData,
  UserIngredientUpdateData,
} from '../types/ingredient'
import { CATEGORY_LABELS, STATUS_LABELS } from '../constants/categories'

type Category = keyof typeof CATEGORY_LABELS;
type IngredientStatus = keyof typeof STATUS_LABELS;
type SortBy = 'recent' | 'expiry_date' | 'quantity';

type GetUserIngredientsParams = {
  status?: IngredientStatus;
  category?: Category;
  sort_by?: SortBy;
  group_by?: 'category';
}

// 一覧取得（group_by対応）
export async function getUserIngredients(params: GetUserIngredientsParams = {}): Promise<UserIngredientListResponse | UserIngredientGroupedResponse> {
  const res = await apiClient.get<UserIngredientListResponse | UserIngredientGroupedResponse>(
    '/user_ingredients', 
    { params }
  );
  return res.data;
}

// 作成（POST）
export async function createUserIngredient(data: UserIngredientCreateData): Promise<UserIngredientSingleResponse> {
  const res = await apiClient.post<UserIngredientSingleResponse>('/user_ingredients', {
    user_ingredient: data,
  });
  return res.data;
}

// 更新（PUT）
export async function updateUserIngredient(id: number, data: UserIngredientUpdateData): Promise<UserIngredientSingleResponse> {
  const res = await apiClient.put<UserIngredientSingleResponse>(`/user_ingredients/${id}`, {
    user_ingredient: data,
  });
  return res.data;
}

// 削除
export async function deleteUserIngredient(id: number): Promise<void> {
  await apiClient.delete(`/user_ingredients/${id}`);
}

