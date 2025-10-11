// 基本的な買い物リスト型
export interface ShoppingList {
  id: number
  userId?: number
  recipeId?: number | null
  title: string | null
  note: string | null
  status: 'pending' | 'in_progress' | 'completed'
  statusDisplay: string
  displayTitle: string
  completionPercentage: number
  totalItemsCount: number
  uncheckedItemsCount: number
  canBeCompleted: boolean
  createdAt: string
  updatedAt: string
  recipe?: Recipe | null
  shoppingListItems?: ShoppingListItem[]
}

// 買い物リストアイテム型
export interface ShoppingListItem {
  id: number
  shoppingListId?: number
  ingredientId?: number
  quantity: number
  unit: string | null
  isChecked: boolean
  checkedAt: string | null
  lockVersion: number
  displayQuantityWithUnit: string
  createdAt: string
  updatedAt: string
  ingredient?: Ingredient
}

// レシピ型（簡易版）
export interface Recipe {
  id: number
  title: string
  description: string | null
  servings: number | null
}

// 食材型（簡易版）
export interface Ingredient {
  id: number
  name: string
  category: string
  displayName?: string
  displayNameWithEmoji?: string
}

// JSON:API レスポンス型
export interface JsonApiResource {
  id: string
  type: string
  attributes: Record<string, unknown>
  relationships?: Record<string, {
    data?: { type: string; id: string } | Array<{ type: string; id: string }>
  }>
}

export interface JsonApiResponse<T = JsonApiResource> {
  data: T | T[]
  included?: JsonApiResource[]
  meta?: Record<string, unknown>
  links?: Record<string, unknown>
}

// 一覧取得時のレスポンス型
export interface ShoppingListsResponse extends JsonApiResponse<JsonApiResource[]> {
  data: JsonApiResource[]
}

// 詳細取得時のレスポンス型
export interface ShoppingListResponse extends JsonApiResponse<JsonApiResource> {
  data: JsonApiResource
}

// API リクエスト/レスポンス型
export interface GetShoppingListsParams {
  page?: number
  per_page?: number
  status?: 'pending' | 'in_progress' | 'completed'
  recipe_id?: number
}

export interface UpdateShoppingListItemRequest {
  shopping_list_item: {
    quantity?: number
    unit?: string
    is_checked?: boolean
    lock_version: number
  }
}

export interface BulkUpdateShoppingListItemsRequest {
  items: Array<{
    id: number
    is_checked: boolean
    lock_version: number
  }>
}

export interface BulkUpdateShoppingListItemsResponse {
  data?: JsonApiResource[]
  errors?: Array<{
    detail: string
  }>
  item_errors?: Array<{
    id: number
    errors: Array<{
      detail: string
    }>
  }>
}

// エラーレスポンス型
export interface ApiError {
  errors: Array<{
    detail: string
    source?: Record<string, unknown>
  }>
}

// 買い物リスト一覧用の型（正規化後）
export interface ShoppingListSummary {
  id: number
  displayTitle: string
  status: 'pending' | 'in_progress' | 'completed'
  statusDisplay: string
  completionPercentage: number
  totalItemsCount: number
  uncheckedItemsCount: number
  canBeCompleted: boolean
  createdAt: string
  recipe?: {
    id: number
    title: string
  } | null
}