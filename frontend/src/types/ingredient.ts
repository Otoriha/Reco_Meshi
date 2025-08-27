// Ingredient型
export interface Ingredient {
  id: number;
  name: string;
  category: 'vegetables' | 'meat' | 'fish' | 'dairy' | 'seasonings' | 'others' | string;
  unit: string;
  emoji: string;
}

// UserIngredient型（サーバーシリアライザ準拠）
export interface UserIngredient {
  id: number;
  user_id: number;
  ingredient_id: number;
  quantity: number;
  status: 'available' | 'used' | 'expired';
  expiry_date: string | null; // YYYY-MM-DD
  ingredient: Ingredient;
  display_name: string;
  formatted_quantity: string;
  days_until_expiry: number | null;
  expired: boolean;
  expiring_soon: boolean;
  created_at: string;
  updated_at: string;
}

// API共通
export interface ApiStatus {
  code: number;
  message: string;
}

// 食材マスタAPIレスポンス
export interface IngredientListResponse {
  status: ApiStatus;
  data: Ingredient[];
}

// ユーザー食材APIレスポンス
export interface UserIngredientListResponse {
  status: ApiStatus;
  data: UserIngredient[];
}

export interface UserIngredientSingleResponse {
  status: ApiStatus;
  data: UserIngredient;
}

export interface UserIngredientGroupedResponse {
  status: ApiStatus;
  data: Record<string, UserIngredient[]>;
}

// 更新/作成用データ型
export interface UserIngredientCreateData {
  ingredient_id: number;
  quantity: number;
  expiry_date?: string | null;
}

export interface UserIngredientUpdateData {
  quantity?: number;
  expiry_date?: string | null;
  status?: 'available' | 'used' | 'expired';
}

