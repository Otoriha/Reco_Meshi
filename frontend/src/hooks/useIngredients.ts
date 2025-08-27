import { useCallback, useEffect, useState } from 'react'
import { getIngredients } from '../api/ingredients'
import type { Ingredient } from '../types/ingredient'

interface UseIngredientsParams {
  page?: number
  perPage?: number
  search?: string
  category?: string
}

export function useIngredients(initial: UseIngredientsParams = {}) {
  const [items, setItems] = useState<Ingredient[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [page, setPage] = useState(initial.page ?? 1)
  const [perPage, setPerPage] = useState(initial.perPage ?? 20)
  const [search, setSearch] = useState(initial.search ?? '')
  const [category, setCategory] = useState(initial.category ?? '')

  const fetch = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await getIngredients({ page, per_page: perPage, search, category })
      setItems(res.data)
    } catch (e) {
      console.error(e)
      setError('食材の取得に失敗しました。')
    } finally {
      setLoading(false)
    }
  }, [page, perPage, search, category])

  useEffect(() => {
    fetch()
  }, [fetch])

  return {
    items,
    loading,
    error,
    page,
    perPage,
    search,
    category,
    setPage,
    setPerPage,
    setSearch,
    setCategory,
    refetch: fetch,
  }
}

