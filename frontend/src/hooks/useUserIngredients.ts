import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  createUserIngredient,
  deleteUserIngredient,
  getUserIngredients,
  updateUserIngredient,
} from '../api/userIngredients'
import type { UserIngredient, UserIngredientGroupedResponse } from '../types/ingredient'

type GroupBy = 'none' | 'category'

interface Filters {
  name?: string
  status?: 'available' | 'used' | 'expired' | ''
  category?: string | ''
  sort_by?: 'expiry_date' | 'quantity' | 'recent'
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
      if (groupBy === 'category') {
        const res = (await getUserIngredients('category')) as UserIngredientGroupedResponse
        setGroups(res.data)
        // フラット化
        const flattened = Object.values(res.data).flat()
        setItems(flattened)
      } else {
        const res = await getUserIngredients()
        setItems(res.data)
        setGroups({})
      }
    } catch (e) {
      console.error(e)
      setError('在庫の取得に失敗しました。')
    } finally {
      setLoading(false)
    }
  }, [groupBy])

  useEffect(() => {
    fetch()
  }, [fetch])

  const filteredItems = useMemo(() => {
    let list = [...items]
    // 名前検索（クライアント側）
    if (filters.name && filters.name.trim() !== '') {
      const q = filters.name.trim().toLowerCase()
      list = list.filter((i) =>
        (i.ingredient?.name ?? i.display_name).toLowerCase().includes(q)
      )
    }
    // カテゴリフィルタ（クライアント側）
    if (filters.category) {
      list = list.filter((i) => (i.ingredient?.category ?? 'others') === filters.category)
    }
    // ステータスフィルタ
    if (filters.status) {
      list = list.filter((i) => i.status === filters.status)
    }
    // ソート
    const sortBy = filters.sort_by ?? 'recent'
    if (sortBy === 'expiry_date') {
      list.sort((a, b) => {
        const da = a.expiry_date ? new Date(a.expiry_date).getTime() : Infinity
        const db = b.expiry_date ? new Date(b.expiry_date).getTime() : Infinity
        return da - db
      })
    } else if (sortBy === 'quantity') {
      list.sort((a, b) => (b.quantity ?? 0) - (a.quantity ?? 0))
    } else {
      // recent: updated_at desc
      list.sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime())
    }
    return list
  }, [items, filters])

  const filteredGroups = useMemo(() => {
    if (groupBy !== 'category') return {}
    // filtersをgroupsに適用
    const result: Record<string, UserIngredient[]> = {}
    Object.keys(groups).forEach((key) => {
      result[key] = filteredItems.filter((i) => (i.ingredient?.category ?? 'others') === key)
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

