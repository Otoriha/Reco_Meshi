import { useState, useEffect, useCallback } from 'react'
import { recipesApi } from '../api/recipes'
import type { Recipe } from '../types/recipe'

export function useRecipes() {
  const [recipes, setRecipes] = useState<Recipe[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchRecipes = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await recipesApi.listRecipes()
      setRecipes(data)
    } catch (err) {
      // 401エラーの場合は、axios interceptorがリダイレクトを処理する
      if (err && typeof err === 'object' && 'response' in err) {
        const axiosError = err as { response?: { status?: number } };
        if (axiosError.response?.status === 401) {
          // 401エラーの場合はinterceptorがリダイレクトするので何もしない
          setError(null);
          return;
        }
      }
      setError(err instanceof Error ? err.message : 'レシピの取得に失敗しました')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchRecipes()
  }, [fetchRecipes])

  return {
    recipes,
    loading,
    error,
    refetch: fetchRecipes
  }
}