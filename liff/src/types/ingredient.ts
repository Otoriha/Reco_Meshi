// 食材マスタ
export interface Ingredient {
  id: number
  name: string
  category: string
  unit: string
  emoji: string
  display_name_with_emoji: string
  created_at: string
  updated_at: string
}

// ユーザー食材（シリアライザ準拠）
export interface UserIngredient {
  id: number
  user_id: number
  ingredient_id: number
  quantity: number
  status: 'available' | 'used' | 'expired'
  expiry_date: string | null // YYYY-MM-DD
  created_at: string
  updated_at: string
  ingredient: Ingredient | null
  display_name: string
  formatted_quantity: string
  days_until_expiry: number | null
  expired: boolean
  expiring_soon: boolean
}

// APIレスポンス
export interface ApiStatus {
  code: number
  message: string
}

export interface UserIngredientListResponse {
  status: ApiStatus
  data: UserIngredient[]
}

export interface UserIngredientSingleResponse {
  status: ApiStatus
  data: UserIngredient
}

export interface UserIngredientGroupedResponse {
  status: ApiStatus
  data: Record<string, UserIngredient[]>
}

// 更新用データ型
export interface UserIngredientUpdateData {
  quantity?: number
  expiry_date?: string | null
  status?: 'available' | 'used' | 'expired'
}

