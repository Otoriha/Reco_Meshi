// 買い物リスト関連の型定義

import type { JsonApiResource, JsonApiResponse } from '../utils/jsonApi'

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
  ingredientName?: string | null
  ingredientDisplayName?: string | null
  ingredientDisplayNameText?: string | null
  ingredientCategory?: string | null
  ingredientEmoji?: string | null
  statusDisplay?: string
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

// 一覧取得時のレスポンス型
export interface ShoppingListsResponse extends JsonApiResponse<JsonApiResource[]> {
  data: JsonApiResource[]
}

// 詳細取得時のレスポンス型
export interface ShoppingListResponse extends JsonApiResponse<JsonApiResource> {
  data: JsonApiResource
}

// アイテム単体のレスポンス型
export interface ShoppingListItemResponse extends JsonApiResponse<JsonApiResource> {
  data: JsonApiResource
}

// API リクエスト/レスポンス型
export interface GetShoppingListsParams {
  page?: number
  per_page?: number
  status?: 'pending' | 'in_progress' | 'completed'
  recipe_id?: number
}

export interface UpdateShoppingListRequest {
  shopping_list: {
    status?: 'pending' | 'in_progress' | 'completed'
    title?: string
    note?: string
  }
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
