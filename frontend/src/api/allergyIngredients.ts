import { apiClient } from './client';
import type { AllergyIngredient, AllergyIngredientCreateData, AllergyIngredientUpdateData } from '../types/allergy';

// アレルギー食材一覧取得
export const getAllergyIngredients = async (): Promise<AllergyIngredient[]> => {
  const response = await apiClient.get('/users/allergy_ingredients');
  return response.data;
};

// アレルギー食材登録
export const createAllergyIngredient = async (data: AllergyIngredientCreateData): Promise<AllergyIngredient> => {
  const response = await apiClient.post('/users/allergy_ingredients', { allergy_ingredient: data });
  return response.data;
};

// アレルギー食材更新
export const updateAllergyIngredient = async (id: number, data: AllergyIngredientUpdateData): Promise<AllergyIngredient> => {
  const response = await apiClient.patch(`/users/allergy_ingredients/${id}`, { allergy_ingredient: data });
  return response.data;
};

// アレルギー食材削除
export const deleteAllergyIngredient = async (id: number): Promise<void> => {
  await apiClient.delete(`/users/allergy_ingredients/${id}`);
};
