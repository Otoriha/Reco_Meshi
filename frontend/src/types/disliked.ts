import type { Ingredient } from './ingredient';

// 苦手食材型（APIレスポンス）
export interface DislikedIngredient {
  id: string;  // JSON:API仕様で文字列
  user_id: number;
  ingredient_id: number;
  priority: 'low' | 'medium' | 'high';
  priority_label: string;
  reason: string | null;
  ingredient: Ingredient;
  created_at: string;
  updated_at: string;
}

// 苦手食材作成用データ
export interface DislikedIngredientCreateData {
  ingredient_id: number;
  priority: 'low' | 'medium' | 'high';
  reason?: string;
}

// 苦手食材更新用データ
export interface DislikedIngredientUpdateData {
  priority?: 'low' | 'medium' | 'high';
  reason?: string;
}
