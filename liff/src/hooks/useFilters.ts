import { useState, useMemo, useCallback } from 'react'
import { startOfWeek, startOfMonth, format } from 'date-fns'
import type { RecipeHistory } from '../types/recipe'
import type { RecipeHistoriesParams } from '../api/recipes'

export type FilterPeriod = 'all' | 'this-week' | 'this-month'

interface Filters {
  period: FilterPeriod
  ratedOnly: boolean | null
  searchQuery: string
}

interface UseFiltersReturn {
  filters: Filters
  setFilters: React.Dispatch<React.SetStateAction<Filters>>
  setPeriod: (period: FilterPeriod) => void
  setRatedOnly: (ratedOnly: boolean | null) => void
  setSearchQuery: (query: string) => void
  getApiParams: () => RecipeHistoriesParams
  filterLocalData: (data: RecipeHistory[]) => RecipeHistory[]
  hasActiveFilters: boolean
  clearFilters: () => void
}

export const useFilters = (): UseFiltersReturn => {
  const [filters, setFilters] = useState<Filters>({
    period: 'all',
    ratedOnly: null,
    searchQuery: ''
  })

  const setPeriod = (period: FilterPeriod) => {
    setFilters(prev => ({ ...prev, period }))
  }

  const setRatedOnly = (ratedOnly: boolean | null) => {
    setFilters(prev => ({ ...prev, ratedOnly }))
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

    // 評価フィルタの処理（評価済みのみサーバーサイド対応）
    if (filters.ratedOnly === true) {
      params.rated_only = true
    }

    return params
  }, [filters.period, filters.ratedOnly])

  const filterLocalData = useMemo(() => {
    return (data: RecipeHistory[]): RecipeHistory[] => {
      let filteredData = data

      // 未評価フィルタ（クライアントサイド）
      if (filters.ratedOnly === false) {
        filteredData = filteredData.filter(item => !item.rating)
      }

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
  }, [filters.ratedOnly, filters.searchQuery])

  const hasActiveFilters = useMemo(() => {
    return filters.period !== 'all' || 
           filters.ratedOnly !== null || 
           filters.searchQuery.trim() !== ''
  }, [filters])

  const clearFilters = () => {
    setFilters({
      period: 'all',
      ratedOnly: null,
      searchQuery: ''
    })
  }

  return {
    filters,
    setFilters,
    setPeriod,
    setRatedOnly,
    setSearchQuery,
    getApiParams,
    filterLocalData,
    hasActiveFilters,
    clearFilters
  }
}