import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  createUserIngredient,
  deleteUserIngredient,
  getUserIngredients,
  updateUserIngredient,
} from '../api/userIngredients'
import type { UserIngredient } from '../types/ingredient'
import { CATEGORY_LABELS, STATUS_LABELS } from '../constants/categories'

type GroupBy = 'none' | 'category'
type Category = keyof typeof CATEGORY_LABELS;
type IngredientStatus = keyof typeof STATUS_LABELS;
type SortBy = 'recent' | 'expiry_date' | 'quantity';

interface Filters {
  name?: string
  status?: IngredientStatus | ''
  category?: Category | ''
  sort_by?: SortBy
}

export function useUserIngredients(initialGroupBy: GroupBy = 'category') {
  const [groupBy, setGroupBy] = useState<GroupBy>(initialGroupBy)
  const [items, setItems] = useState<UserIngredient[]>([])
  const [groups, setGroups] = useState<Record<string, UserIngredient[]>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<Filters>({ sort_by: 'recent' })

  const fetch = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const params = {
        ...(groupBy === 'category' && { group_by: 'category' as const }),
        status: filters.status || undefined,
        category: filters.category || undefined,
        sort_by: filters.sort_by && filters.sort_by !== 'recent' ? filters.sort_by : undefined,
      };

      const res = await getUserIngredients(params);
      
      if (groupBy === 'category' && 'data' in res && typeof res.data === 'object' && !Array.isArray(res.data)) {
        setGroups(res.data as Record<string, UserIngredient[]>);
        // フラット化
        const flattened = Object.values(res.data as Record<string, UserIngredient[]>).flat();
        setItems(flattened);
      } else if ('data' in res && Array.isArray(res.data)) {
        setItems(res.data);
        setGroups({});
      }
    } catch (e) {
      console.error(e)
      setError('在庫の取得に失敗しました。')
    } finally {
      setLoading(false)
    }
  }, [groupBy, filters.status, filters.category, filters.sort_by])

  useEffect(() => {
    fetch()
  }, [fetch])

  const filteredItems = useMemo(() => {
    let list = [...items]
    // 名前検索のみクライアント側（サーバー側でフィルタ・ソート済み）
    if (filters.name && filters.name.trim() !== '') {
      const q = filters.name.trim().toLowerCase()
      list = list.filter((i) =>
        (i.ingredient?.name ?? i.display_name).toLowerCase().includes(q)
      )
    }
    return list
  }, [items, filters.name])

  const filteredGroups = useMemo(() => {
    if (groupBy !== 'category') return {}
    const result: Record<string, UserIngredient[]> = {}
    Object.keys(groups).forEach((key) => {
      const arr = filteredItems.filter((i) => (i.ingredient?.category ?? 'others') === key)
      if (arr.length) result[key] = arr
    })
    return result
  }, [groupBy, groups, filteredItems])

  // CRUD
  const add = useCallback(async (data: { ingredient_id: number; quantity: number; expiry_date?: string | null }) => {
    const res = await createUserIngredient(data)
    const item = res.data
    setItems((prev) => [item, ...prev])
    if (groupBy === 'category') {
      const cat = item.ingredient?.category ?? 'others'
      setGroups((prev) => ({
        ...prev,
        [cat]: [item, ...(prev[cat] || [])],
      }))
    }
    return item
  }, [groupBy])

  const update = useCallback(async (id: number, data: { quantity?: number; expiry_date?: string | null; status?: 'available' | 'used' | 'expired' }) => {
    const res = await updateUserIngredient(id, data)
    const updated = res.data
    setItems((prev) => prev.map((i) => (i.id === updated.id ? updated : i)))
    if (groupBy === 'category') {
      const cat = updated.ingredient?.category ?? 'others'
      setGroups((prev) => {
        const next = { ...prev }
        // 全カテゴリから該当アイテムを除去
        Object.keys(next).forEach((k) => {
          next[k] = (next[k] || []).filter((i) => i.id !== updated.id)
        })
        next[cat] = [updated, ...(next[cat] || [])]
        return next
      })
    }
    return updated
  }, [groupBy])

  const remove = useCallback(async (id: number) => {
    await deleteUserIngredient(id)
    setItems((prev) => prev.filter((i) => i.id !== id))
    if (groupBy === 'category') {
      setGroups((prev) => {
        const next = { ...prev }
        Object.keys(next).forEach((k) => {
          next[k] = (next[k] || []).filter((i) => i.id !== id)
          if (next[k].length === 0) delete next[k]
        })
        return next
      })
    }
  }, [groupBy])

  return {
    groupBy,
    setGroupBy,
    loading,
    error,
    filters,
    setFilters,
    items: filteredItems,
    groups: filteredGroups,
    refetch: fetch,
    add,
    update,
    remove,
  }
}

