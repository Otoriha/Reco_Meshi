import { apiClient } from './client'
import {
  normalizeJsonApiResource,
  convertKeysToSnakeCase,
  type ApiError
} from '../utils/jsonApi'
import type {
  ShoppingList,
  ShoppingListItem,
  ShoppingListSummary,
  ShoppingListsResponse,
  ShoppingListResponse,
  GetShoppingListsParams,
  UpdateShoppingListRequest,
  UpdateShoppingListItemRequest,
  BulkUpdateShoppingListItemsRequest,
  BulkUpdateShoppingListItemsResponse
} from '../types/shoppingList'

// API関数群

/**
 * 買い物リスト一覧を取得
 * @param params ページネーション、ステータスフィルタ
 * @returns 買い物リストのサマリー配列
 */
export async function getShoppingLists(params: GetShoppingListsParams = {}): Promise<ShoppingListSummary[]> {
  try {
    const response = await apiClient.get<ShoppingListsResponse>('/shopping_lists', { params })
    
    if (!Array.isArray(response.data.data)) {
      return []
    }

    return response.data.data.map(resource => 
      normalizeJsonApiResource(resource, response.data.included || [])
    ) as ShoppingListSummary[]
  } catch (error: any) {
    if (error.response?.status === 404) {
      return []
    }
    throw error
  }
}

/**
 * 買い物リスト詳細を取得
 * @param id 買い物リストID
 * @returns 買い物リストの詳細（アイテム含む）
 */
export async function getShoppingList(id: number): Promise<ShoppingList> {
  const response = await apiClient.get<ShoppingListResponse>(`/shopping_lists/${id}`)
  
  if (Array.isArray(response.data.data)) {
    throw new Error('Expected single resource, got array')
  }

  return normalizeJsonApiResource(response.data.data, response.data.included || []) as ShoppingList
}

/**
 * 買い物リストを作成
 * @param recipeId レシピID（省略可能）
 * @returns 作成された買い物リスト
 */
export async function createShoppingList(recipeId?: number): Promise<ShoppingList> {
  const params = recipeId ? { recipe_id: recipeId } : {}
  const response = await apiClient.post<ShoppingListResponse>('/shopping_lists', params)
  
  if (Array.isArray(response.data.data)) {
    throw new Error('Expected single resource, got array')
  }

  return normalizeJsonApiResource(response.data.data, response.data.included || []) as ShoppingList
}

/**
 * 買い物リストを更新
 * @param id 買い物リストID
 * @param updates 更新内容
 * @returns 更新された買い物リスト
 */
export async function updateShoppingList(
  id: number,
  updates: {
    status?: 'pending' | 'in_progress' | 'completed'
    title?: string
    note?: string
  }
): Promise<ShoppingList> {
  const requestBody: UpdateShoppingListRequest = {
    shopping_list: convertKeysToSnakeCase(updates) as any
  }

  const response = await apiClient.patch<ShoppingListResponse>(`/shopping_lists/${id}`, requestBody)
  
  if (Array.isArray(response.data.data)) {
    throw new Error('Expected single resource, got array')
  }

  return normalizeJsonApiResource(response.data.data, response.data.included || []) as ShoppingList
}

/**
 * 買い物リストアイテムを更新
 * @param shoppingListId 買い物リストID
 * @param itemId アイテムID
 * @param updates 更新内容（lockVersionは必須）
 * @returns 更新されたアイテム
 */
export async function updateShoppingListItem(
  shoppingListId: number,
  itemId: number,
  updates: {
    quantity?: number
    unit?: string
    isChecked?: boolean
    lockVersion: number
  }
): Promise<ShoppingListItem> {
  const requestBody: UpdateShoppingListItemRequest = {
    shopping_list_item: convertKeysToSnakeCase(updates) as {
      quantity?: number
      unit?: string
      is_checked?: boolean
      lock_version: number
    }
  }

  const response = await apiClient.patch<ShoppingListResponse>(
    `/shopping_lists/${shoppingListId}/items/${itemId}`,
    requestBody
  )

  if (Array.isArray(response.data.data)) {
    throw new Error('Expected single resource, got array')
  }

  return normalizeJsonApiResource(response.data.data, response.data.included || []) as ShoppingListItem
}

/**
 * 買い物リストアイテムを一括更新
 * @param shoppingListId 買い物リストID
 * @param items 更新するアイテムの配列
 * @returns 更新されたアイテムの配列
 */
export async function bulkUpdateShoppingListItems(
  shoppingListId: number,
  items: Array<{
    id: number
    isChecked: boolean
    lockVersion: number
  }>
): Promise<ShoppingListItem[]> {
  const requestBody: BulkUpdateShoppingListItemsRequest = {
    items: items.map(item => convertKeysToSnakeCase(item) as {
      id: number
      is_checked: boolean
      lock_version: number
    })
  }

  const response = await apiClient.patch<BulkUpdateShoppingListItemsResponse>(
    `/shopping_lists/${shoppingListId}/items/bulk_update`,
    requestBody
  )

  if (response.data.errors) {
    const error = new Error(response.data.errors[0]?.detail || 'Bulk update failed') as any
    error.itemErrors = response.data.item_errors
    throw error
  }

  if (!response.data.data) {
    return []
  }

  return response.data.data.map(resource => 
    normalizeJsonApiResource(resource, [])
  ) as ShoppingListItem[]
}

/**
 * 買い物リストを完了状態にする
 * @param id 買い物リストID
 * @returns 完了した買い物リスト
 */
export async function completeShoppingList(id: number): Promise<ShoppingList> {
  const response = await apiClient.patch<ShoppingListResponse>(`/shopping_lists/${id}/complete`)
  
  if (Array.isArray(response.data.data)) {
    throw new Error('Expected single resource, got array')
  }

  return normalizeJsonApiResource(response.data.data, response.data.included || []) as ShoppingList
}

/**
 * 買い物リストを削除
 * @param id 買い物リストID
 */
export async function deleteShoppingList(id: number): Promise<void> {
  await apiClient.delete(`/shopping_lists/${id}`)
}

/**
 * エラーハンドリングヘルパー
 * @param error エラーオブジェクト
 * @returns ユーザー向けエラーメッセージ
 */
export function getShoppingListErrorMessage(error: any): string {
  if (error.response?.status === 409) {
    return '他のユーザーによって更新されています。画面を再読み込みして最新の状態を確認してください。'
  }
  if (error.response?.status === 403) {
    return 'アクセス権限がありません。'
  }
  if (error.response?.status === 404) {
    return '買い物リストが見つかりません。'
  }
  if (error.response?.data?.errors?.[0]?.detail) {
    return error.response.data.errors[0].detail
  }
  if (error.message) {
    return error.message
  }
  return '予期しないエラーが発生しました。'
}