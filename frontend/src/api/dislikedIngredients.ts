import { apiClient } from './client';
import type { DislikedIngredient, DislikedIngredientCreateData, DislikedIngredientUpdateData } from '../types/disliked';

// 苦手食材一覧取得
export const getDislikedIngredients = async (): Promise<DislikedIngredient[]> => {
  const response = await apiClient.get('/users/disliked_ingredients');
  return response.data;
};

// 苦手食材登録
export const createDislikedIngredient = async (data: DislikedIngredientCreateData): Promise<DislikedIngredient> => {
  const response = await apiClient.post('/users/disliked_ingredients', { disliked_ingredient: data });
  return response.data;
};

// 苦手食材更新
export const updateDislikedIngredient = async (id: number, data: DislikedIngredientUpdateData): Promise<DislikedIngredient> => {
  const response = await apiClient.patch(`/users/disliked_ingredients/${id}`, { disliked_ingredient: data });
  return response.data;
};

// 苦手食材削除
export const deleteDislikedIngredient = async (id: number): Promise<void> => {
  await apiClient.delete(`/users/disliked_ingredients/${id}`);
};
