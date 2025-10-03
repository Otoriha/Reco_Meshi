import { useState, useCallback } from 'react'
import { recipesApi } from '../api/recipes'
import type { FavoriteRecipe, FavoriteRecipesParams, PaginationMeta } from '../types/recipe'

interface UseFavoriteRecipesState {
  favorites: FavoriteRecipe[]
  meta: PaginationMeta | null
  loading: boolean
  error: string | null
  initialized: boolean
}

interface UseFavoriteRecipesReturn extends UseFavoriteRecipesState {
  fetchFavorites: (params?: FavoriteRecipesParams) => Promise<void>
  addFavorite: (recipeId: number, rating?: number | null) => Promise<void>
  removeFavorite: (favoriteId: number) => Promise<void>
  updateRating: (favoriteId: number, rating: number | null) => Promise<void>
  refreshFavorites: () => Promise<void>
  currentPage: number
  totalPages: number
  hasNextPage: boolean
  hasPrevPage: boolean
  goToPage: (page: number) => Promise<void>
  goToNextPage: () => Promise<void>
  goToPrevPage: () => Promise<void>
}

const INITIAL_STATE: UseFavoriteRecipesState = {
  favorites: [],
  meta: null,
  loading: false,
  error: null,
  initialized: false
}

export const useFavoriteRecipes = (): UseFavoriteRecipesReturn => {
  const [state, setState] = useState<UseFavoriteRecipesState>(INITIAL_STATE)
  const [currentParams, setCurrentParams] = useState<FavoriteRecipesParams>({})

  const fetchFavorites = useCallback(async (params: FavoriteRecipesParams = {}): Promise<void> => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }))
      setCurrentParams(params)

      const defaultParams = { per_page: 20, page: 1, ...params }
      const result = await recipesApi.fetchFavoriteRecipes(defaultParams)

      setState(prev => ({
        ...prev,
        favorites: result.data,
        meta: result.meta,
        loading: false,
        initialized: true
      }))
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'お気に入りの取得に失敗しました'
      setState(prev => ({
        ...prev,
        error: errorMessage,
        loading: false,
        initialized: true
      }))
    }
  }, [])

  const addFavorite = useCallback(async (recipeId: number, rating?: number | null): Promise<void> => {
    try {
      const newFavorite = await recipesApi.addFavoriteRecipe({ recipe_id: recipeId, rating })

      setState(prev => ({
        ...prev,
        favorites: [newFavorite, ...prev.favorites],
        meta: prev.meta ? {
          ...prev.meta,
          total_count: prev.meta.total_count + 1
        } : null
      }))
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'お気に入りの追加に失敗しました'
      throw new Error(errorMessage)
    }
  }, [])

  const removeFavorite = useCallback(async (favoriteId: number): Promise<void> => {
    try {
      await recipesApi.removeFavoriteRecipe(favoriteId)

      setState(prev => {
        const newFavorites = prev.favorites.filter(favorite => favorite.id !== favoriteId)
        const newMeta = prev.meta ? {
          ...prev.meta,
          total_count: prev.meta.total_count - 1
        } : null

        return {
          ...prev,
          favorites: newFavorites,
          meta: newMeta
        }
      })
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'お気に入りの削除に失敗しました'
      throw new Error(errorMessage)
    }
  }, [])

  const updateRating = useCallback(async (favoriteId: number, rating: number | null): Promise<void> => {
    try {
      const updatedFavorite = await recipesApi.updateFavoriteRecipe(favoriteId, { rating })

      setState(prev => ({
        ...prev,
        favorites: prev.favorites.map(favorite =>
          favorite.id === favoriteId ? updatedFavorite : favorite
        )
      }))
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : '評価の更新に失敗しました'
      throw new Error(errorMessage)
    }
  }, [])

  const refreshFavorites = useCallback(async (): Promise<void> => {
    await fetchFavorites(currentParams)
  }, [fetchFavorites, currentParams])

  const goToPage = useCallback(async (page: number): Promise<void> => {
    await fetchFavorites({ ...currentParams, page })
  }, [fetchFavorites, currentParams])

  const goToNextPage = useCallback(async (): Promise<void> => {
    if (state.meta && state.meta.current_page < state.meta.total_pages) {
      await goToPage(state.meta.current_page + 1)
    }
  }, [state.meta, goToPage])

  const goToPrevPage = useCallback(async (): Promise<void> => {
    if (state.meta && state.meta.current_page > 1) {
      await goToPage(state.meta.current_page - 1)
    }
  }, [state.meta, goToPage])

  const currentPage = state.meta?.current_page || 1
  const totalPages = state.meta?.total_pages || 0
  const hasNextPage = currentPage < totalPages
  const hasPrevPage = currentPage > 1

  return {
    ...state,
    fetchFavorites,
    addFavorite,
    removeFavorite,
    updateRating,
    refreshFavorites,
    currentPage,
    totalPages,
    hasNextPage,
    hasPrevPage,
    goToPage,
    goToNextPage,
    goToPrevPage
  }
}
