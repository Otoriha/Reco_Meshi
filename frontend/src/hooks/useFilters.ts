import { useState, useMemo, useCallback } from 'react'
import { startOfWeek, startOfMonth, format } from 'date-fns'
import type { RecipeHistory, RecipeHistoriesParams } from '../types/recipe'

export type FilterPeriod = 'all' | 'this-week' | 'this-month'

interface Filters {
  period: FilterPeriod
  favoritedOnly: boolean | null
  searchQuery: string
}

interface UseFiltersReturn {
  filters: Filters
  setFilters: React.Dispatch<React.SetStateAction<Filters>>
  setPeriod: (period: FilterPeriod) => void
  setFavoritedOnly: (favoritedOnly: boolean | null) => void
  setSearchQuery: (query: string) => void
  getApiParams: () => RecipeHistoriesParams
  filterLocalData: (data: RecipeHistory[]) => RecipeHistory[]
  hasActiveFilters: boolean
  clearFilters: () => void
}

export const useFilters = (): UseFiltersReturn => {
  const [filters, setFilters] = useState<Filters>({
    period: 'all',
    favoritedOnly: null,
    searchQuery: ''
  })

  const setPeriod = (period: FilterPeriod) => {
    setFilters(prev => ({ ...prev, period }))
  }

  const setFavoritedOnly = (favoritedOnly: boolean | null) => {
    setFilters(prev => ({ ...prev, favoritedOnly }))
  }

  const setSearchQuery = (searchQuery: string) => {
    setFilters(prev => ({ ...prev, searchQuery }))
  }

  const getApiParams = useCallback((): RecipeHistoriesParams => {
    const params: RecipeHistoriesParams = {}

    // 期間フィルタの処理
    if (filters.period !== 'all') {
      const now = new Date()

      if (filters.period === 'this-week') {
        const weekStart = startOfWeek(now, { weekStartsOn: 1 }) // 月曜日開始
        params.start_date = format(weekStart, 'yyyy-MM-dd')
      } else if (filters.period === 'this-month') {
        const monthStart = startOfMonth(now)
        params.start_date = format(monthStart, 'yyyy-MM-dd')
      }
    }

    // お気に入りフィルタの処理（サーバーサイドで対応）
    if (filters.favoritedOnly !== null) {
      params.favorited_only = filters.favoritedOnly
    }

    return params
  }, [filters.period, filters.favoritedOnly])

  const filterLocalData = useMemo(() => {
    return (data: RecipeHistory[]): RecipeHistory[] => {
      let filteredData = data

      // 検索フィルタ（クライアントサイド）
      if (filters.searchQuery.trim()) {
        const query = filters.searchQuery.toLowerCase().trim()
        filteredData = filteredData.filter(item =>
          item.recipe?.title?.toLowerCase().includes(query) ||
          item.memo?.toLowerCase().includes(query)
        )
      }

      return filteredData
    }
  }, [filters.searchQuery])

  const hasActiveFilters = useMemo(() => {
    return filters.period !== 'all' ||
           filters.favoritedOnly !== null ||
           filters.searchQuery.trim() !== ''
  }, [filters])

  const clearFilters = () => {
    setFilters({
      period: 'all',
      favoritedOnly: null,
      searchQuery: ''
    })
  }

  return {
    filters,
    setFilters,
    setPeriod,
    setFavoritedOnly,
    setSearchQuery,
    getApiParams,
    filterLocalData,
    hasActiveFilters,
    clearFilters
  }
}