import type { Ingredient } from './ingredient';

// アレルギー食材型（APIレスポンス）
export interface AllergyIngredient {
  id: number;
  user_id: number;
  ingredient_id: number;
  severity: 'mild' | 'moderate' | 'severe';
  severity_label: string;
  note: string | null;
  ingredient: Ingredient;
  created_at: string;
  updated_at: string;
}

// アレルギー食材作成用データ
export interface AllergyIngredientCreateData {
  ingredient_id: number;
  severity: 'mild' | 'moderate' | 'severe';
  note?: string;
}

// アレルギー食材更新用データ
export interface AllergyIngredientUpdateData {
  severity?: 'mild' | 'moderate' | 'severe';
  note?: string;
}
