// JSON:API正規化ユーティリティ

export interface JsonApiResource {
  id: string
  type: string
  attributes: Record<string, any>
  relationships?: Record<string, any>
}

export interface JsonApiResponse<T = JsonApiResource> {
  data: T | T[]
  included?: JsonApiResource[]
  meta?: Record<string, any>
  links?: Record<string, any>
}

/**
 * snake_caseからcamelCaseに変換
 */
export function convertKeyFromSnakeCase(key: string): string {
  return key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase())
}

/**
 * camelCaseからsnake_caseに変換
 */
export function convertKeyToSnakeCase(key: string): string {
  return key.replace(/([A-Z])/g, '_$1').toLowerCase()
}

/**
 * オブジェクトのキーをsnake_caseからcamelCaseに変換
 */
export function convertKeysFromSnakeCase(obj: Record<string, any>): Record<string, any> {
  const result: Record<string, any> = {}
  Object.entries(obj).forEach(([key, value]) => {
    result[convertKeyFromSnakeCase(key)] = value
  })
  return result
}

/**
 * オブジェクトのキーをcamelCaseからsnake_caseに変換
 */
export function convertKeysToSnakeCase(obj: Record<string, any>): Record<string, any> {
  const result: Record<string, any> = {}
  Object.entries(obj).forEach(([key, value]) => {
    result[convertKeyToSnakeCase(key)] = value
  })
  return result
}

/**
 * includedからリソースを検索
 */
export function findIncludedResource(
  type: string,
  id: string,
  included: JsonApiResource[]
): JsonApiResource | null {
  return included.find(res => res.type === type && res.id === id) || null
}

/**
 * JSON:APIリソースを正規化
 */
export function normalizeJsonApiResource(
  resource: JsonApiResource,
  included: JsonApiResource[] = []
): Record<string, any> {
  const normalized: Record<string, any> = {
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

/**
 * API エラーレスポンス型
 */
export interface ApiError {
  errors: Array<{
    detail: string
    source?: Record<string, any>
  }>
}

/**
 * エラーレスポンスのフォーマット
 */
export function formatApiErrors(errors: any[]): ApiError {
  return {
    errors: errors.map(error => ({
      detail: typeof error === 'string' ? error : error.detail || 'An error occurred',
      source: error.source
    }))
  }
}