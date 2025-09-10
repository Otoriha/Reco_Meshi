import { useState, useCallback } from 'react'
import { recipesApi } from '../api/recipes'
import type { RecipeHistory, UpdateRecipeHistoryParams, PaginationMeta, RecipeHistoriesParams } from '../types/recipe'

interface UseRecipeHistoryState {
  histories: RecipeHistory[]
  meta: PaginationMeta | null
  loading: boolean
  error: string | null
  initialized: boolean
}

interface UseRecipeHistoryReturn extends UseRecipeHistoryState {
  fetchHistories: (params?: RecipeHistoriesParams) => Promise<void>
  updateHistory: (id: number, params: UpdateRecipeHistoryParams) => Promise<void>
  deleteHistory: (id: number) => Promise<void>
  refreshHistories: () => Promise<void>
  currentPage: number
  totalPages: number
  hasNextPage: boolean
  hasPrevPage: boolean
  goToPage: (page: number) => Promise<void>
  goToNextPage: () => Promise<void>
  goToPrevPage: () => Promise<void>
}

const INITIAL_STATE: UseRecipeHistoryState = {
  histories: [],
  meta: null,
  loading: false,
  error: null,
  initialized: false
}

export const useRecipeHistory = (): UseRecipeHistoryReturn => {
  const [state, setState] = useState<UseRecipeHistoryState>(INITIAL_STATE)
  const [currentParams, setCurrentParams] = useState<RecipeHistoriesParams>({})

  const fetchHistories = useCallback(async (params: RecipeHistoriesParams = {}): Promise<void> => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }))
      setCurrentParams(params)

      const defaultParams = { per_page: 20, page: 1, ...params }
      const result = await recipesApi.fetchRecipeHistories(defaultParams)

      setState(prev => ({
        ...prev,
        histories: result.data,
        meta: result.meta,
        loading: false,
        initialized: true
      }))
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : '調理履歴の取得に失敗しました'
      setState(prev => ({
        ...prev,
        error: errorMessage,
        loading: false,
        initialized: true
      }))
    }
  }, [])

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
    await fetchHistories(currentParams)
  }, [fetchHistories, currentParams])

  const goToPage = useCallback(async (page: number): Promise<void> => {
    const params = { ...currentParams, page }
    await fetchHistories(params)
  }, [fetchHistories, currentParams])

  const goToNextPage = useCallback(async (): Promise<void> => {
    if (state.meta && state.meta.current_page < state.meta.total_pages) {
      await goToPage(state.meta.current_page + 1)
    }
  }, [goToPage, state.meta])

  const goToPrevPage = useCallback(async (): Promise<void> => {
    if (state.meta && state.meta.current_page > 1) {
      await goToPage(state.meta.current_page - 1)
    }
  }, [goToPage, state.meta])

  const currentPage = state.meta?.current_page || 1
  const totalPages = state.meta?.total_pages || 1
  const hasNextPage = state.meta ? state.meta.current_page < state.meta.total_pages : false
  const hasPrevPage = state.meta ? state.meta.current_page > 1 : false

  return {
    ...state,
    fetchHistories,
    updateHistory,
    deleteHistory,
    refreshHistories,
    currentPage,
    totalPages,
    hasNextPage,
    hasPrevPage,
    goToPage,
    goToNextPage,
    goToPrevPage
  }
}