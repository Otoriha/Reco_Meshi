import { useState, useEffect, useCallback, useMemo } from 'react'
import { recipesApi } from '../api/recipes'
import type { RecipeHistory, UpdateRecipeHistoryParams } from '../types/recipe'
import type { PaginationMeta, RecipeHistoriesParams } from '../api/recipes'
import { hasMorePages } from './useInfiniteScroll'

interface UseRecipeHistoryState {
  histories: RecipeHistory[]
  meta: PaginationMeta | null
  loading: boolean
  loadingMore: boolean
  error: string | null
  initialized: boolean
}

interface UseRecipeHistoryReturn extends UseRecipeHistoryState {
  fetchHistories: (params?: RecipeHistoriesParams, replace?: boolean) => Promise<void>
  loadMore: () => Promise<void>
  updateHistory: (id: number, params: UpdateRecipeHistoryParams) => Promise<void>
  deleteHistory: (id: number) => Promise<void>
  refreshHistories: () => Promise<void>
  hasNextPage: boolean
  currentPage: number
}

const INITIAL_STATE: UseRecipeHistoryState = {
  histories: [],
  meta: null,
  loading: false,
  loadingMore: false,
  error: null,
  initialized: false
}

export const useRecipeHistory = (): UseRecipeHistoryReturn => {
  const [state, setState] = useState<UseRecipeHistoryState>(INITIAL_STATE)

  const fetchHistories = useCallback(async (
    params: RecipeHistoriesParams = {}, 
    replace = true
  ): Promise<void> => {
    try {
      if (replace) {
        setState(prev => ({ ...prev, loading: true, error: null }))
      } else {
        setState(prev => ({ ...prev, loadingMore: true, error: null }))
      }

      const defaultParams = { per_page: 20, page: 1, ...params }
      const result = await recipesApi.fetchRecipeHistories(defaultParams)

      setState(prev => ({
        ...prev,
        histories: replace ? result.data : [...prev.histories, ...result.data],
        meta: result.meta,
        loading: false,
        loadingMore: false,
        initialized: true
      }))
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : '調理履歴の取得に失敗しました'
      setState(prev => ({
        ...prev,
        error: errorMessage,
        loading: false,
        loadingMore: false,
        initialized: true
      }))
    }
  }, [])

  const loadMore = useCallback(async (): Promise<void> => {
    if (!state.meta || !hasMorePages(state.meta) || state.loadingMore) {
      return
    }

    const nextPage = state.meta.current_page + 1
    await fetchHistories({ page: nextPage }, false)
  }, [state.meta, state.loadingMore, fetchHistories])

  const updateHistory = useCallback(async (
    id: number, 
    params: UpdateRecipeHistoryParams
  ): Promise<void> => {
    try {
      const updatedHistory = await recipesApi.updateRecipeHistory(id, params)
      
      setState(prev => ({
        ...prev,
        histories: prev.histories.map(history =>
          history.id === id ? updatedHistory : history
        )
      }))
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : '調理記録の更新に失敗しました'
      throw new Error(errorMessage)
    }
  }, [])

  const deleteHistory = useCallback(async (id: number): Promise<void> => {
    try {
      await recipesApi.deleteRecipeHistory(id)
      
      setState(prev => ({
        ...prev,
        histories: prev.histories.filter(history => history.id !== id),
        meta: prev.meta ? {
          ...prev.meta,
          total_count: prev.meta.total_count - 1
        } : null
      }))
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : '調理記録の削除に失敗しました'
      throw new Error(errorMessage)
    }
  }, [])

  const refreshHistories = useCallback(async (): Promise<void> => {
    await fetchHistories({}, true)
  }, [fetchHistories])

  // 初回データ取得
  useEffect(() => {
    if (!state.initialized) {
      fetchHistories()
    }
  }, [state.initialized, fetchHistories])

  const hasNextPage = useMemo(() => {
    return hasMorePages(state.meta || undefined)
  }, [state.meta])

  const currentPage = useMemo(() => {
    return state.meta?.current_page || 1
  }, [state.meta])

  return {
    ...state,
    fetchHistories,
    loadMore,
    updateHistory,
    deleteHistory,
    refreshHistories,
    hasNextPage,
    currentPage
  }
}