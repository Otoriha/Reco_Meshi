import { apiClient } from './client'
import type {
  ShoppingList,
  ShoppingListItem,
  ShoppingListSummary,
  Recipe,
  Ingredient,
  JsonApiResource,
  JsonApiResponse,
  ShoppingListsResponse,
  ShoppingListResponse,
  GetShoppingListsParams,
  UpdateShoppingListItemRequest,
  BulkUpdateShoppingListItemsRequest,
  BulkUpdateShoppingListItemsResponse
} from '../types/shoppingList'

// JSON:API正規化ユーティリティ
function normalizeJsonApiResource(resource: JsonApiResource, included: JsonApiResource[] = []): any {
  const normalized = {
    id: Number(resource.id),
    ...convertKeysFromSnakeCase(resource.attributes)
  }

  // リレーションシップの処理
  if (resource.relationships) {
    Object.entries(resource.relationships).forEach(([key, relationship]: [string, any]) => {
      if (relationship.data) {
        if (Array.isArray(relationship.data)) {
          // 複数のリレーション
          normalized[convertKeyFromSnakeCase(key)] = relationship.data
            .map((rel: any) => findIncludedResource(rel.type, rel.id, included))
            .filter(Boolean)
            .map((res: JsonApiResource) => normalizeJsonApiResource(res, included))
        } else {
          // 単一のリレーション
          const relatedResource = findIncludedResource(
            relationship.data.type,
            relationship.data.id,
            included
          )
          if (relatedResource) {
            normalized[convertKeyFromSnakeCase(key)] = normalizeJsonApiResource(relatedResource, included)
          }
        }
      }
    })
  }

  return normalized
}

function findIncludedResource(type: string, id: string, included: JsonApiResource[]): JsonApiResource | null {
  return included.find(res => res.type === type && res.id === id) || null
}

function convertKeysFromSnakeCase(obj: Record<string, any>): Record<string, any> {
  const result: Record<string, any> = {}
  Object.entries(obj).forEach(([key, value]) => {
    result[convertKeyFromSnakeCase(key)] = value
  })
  return result
}

function convertKeyFromSnakeCase(key: string): string {
  return key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase())
}

function convertKeysToSnakeCase(obj: Record<string, any>): Record<string, any> {
  const result: Record<string, any> = {}
  Object.entries(obj).forEach(([key, value]) => {
    result[convertKeyToSnakeCase(key)] = value
  })
  return result
}

function convertKeyToSnakeCase(key: string): string {
  return key.replace(/([A-Z])/g, '_$1').toLowerCase()
}

// API関数群

/**
 * 買い物リスト一覧を取得
 */
export async function getShoppingLists(params: GetShoppingListsParams = {}): Promise<ShoppingListSummary[]> {
  const response = await apiClient.get<ShoppingListsResponse>('/shopping_lists', { params })
  
  if (!Array.isArray(response.data.data)) {
    return []
  }

  return response.data.data.map(resource => 
    normalizeJsonApiResource(resource, response.data.included || [])
  ) as ShoppingListSummary[]
}

/**
 * 買い物リスト詳細を取得
 */
export async function getShoppingList(id: number): Promise<ShoppingList> {
  const response = await apiClient.get<ShoppingListResponse>(`/shopping_lists/${id}`)
  
  if (Array.isArray(response.data.data)) {
    throw new Error('Expected single resource, got array')
  }

  return normalizeJsonApiResource(response.data.data, response.data.included || []) as ShoppingList
}

/**
 * 買い物リストアイテムを更新
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
    shopping_list_item: {
      ...convertKeysToSnakeCase(updates)
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
    items: items.map(item => convertKeysToSnakeCase(item))
  }

  const response = await apiClient.patch<BulkUpdateShoppingListItemsResponse>(
    `/shopping_lists/${shoppingListId}/items/bulk_update`,
    requestBody
  )

  if (response.data.errors) {
    throw new Error(response.data.errors[0]?.detail || 'Bulk update failed')
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
 */
export async function deleteShoppingList(id: number): Promise<void> {
  await apiClient.delete(`/shopping_lists/${id}`)
}

/**
 * 買い物リストを更新（ステータス、タイトル、ノートなど）
 */
export async function updateShoppingList(
  id: number,
  updates: {
    status?: 'pending' | 'in_progress' | 'completed'
    title?: string
    note?: string
  }
): Promise<ShoppingList> {
  const requestBody = {
    shopping_list: convertKeysToSnakeCase(updates)
  }

  const response = await apiClient.patch<ShoppingListResponse>(`/shopping_lists/${id}`, requestBody)
  
  if (Array.isArray(response.data.data)) {
    throw new Error('Expected single resource, got array')
  }

  return normalizeJsonApiResource(response.data.data, response.data.included || []) as ShoppingList
}