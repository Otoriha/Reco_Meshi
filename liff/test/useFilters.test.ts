import { describe, it, expect, beforeEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useFilters } from '../src/hooks/useFilters'
import type { RecipeHistory } from '../src/types/recipe'

describe('useFilters', () => {
  it('初期状態が正しく設定される', () => {
    const { result } = renderHook(() => useFilters())
    
    expect(result.current.filters.period).toBe('all')
    expect(result.current.filters.ratedOnly).toBe(null)
    expect(result.current.filters.searchQuery).toBe('')
    expect(result.current.hasActiveFilters).toBe(false)
  })

  it('期間フィルタが正しく設定される', () => {
    const { result } = renderHook(() => useFilters())
    
    act(() => {
      result.current.setPeriod('this-week')
    })
    
    expect(result.current.filters.period).toBe('this-week')
    expect(result.current.hasActiveFilters).toBe(true)
  })

  it('評価フィルタが正しく設定される', () => {
    const { result } = renderHook(() => useFilters())
    
    act(() => {
      result.current.setRatedOnly(true)
    })
    
    expect(result.current.filters.ratedOnly).toBe(true)
    expect(result.current.hasActiveFilters).toBe(true)
  })

  it('検索クエリが正しく設定される', () => {
    const { result } = renderHook(() => useFilters())
    
    act(() => {
      result.current.setSearchQuery('カレー')
    })
    
    expect(result.current.filters.searchQuery).toBe('カレー')
    expect(result.current.hasActiveFilters).toBe(true)
  })

  it('getApiParamsが正しいパラメータを返す', () => {
    const { result } = renderHook(() => useFilters())
    
    act(() => {
      result.current.setPeriod('this-week')
      result.current.setRatedOnly(true)
    })
    
    const apiParams = result.current.getApiParams()
    
    expect(apiParams.start_date).toBeDefined()
    expect(apiParams.rated_only).toBe(true)
  })

  it('今月フィルタが正しいstart_dateを設定する', () => {
    const { result } = renderHook(() => useFilters())
    
    act(() => {
      result.current.setPeriod('this-month')
    })
    
    const apiParams = result.current.getApiParams()
    
    expect(apiParams.start_date).toMatch(/^\d{4}-\d{2}-01$/) // 月初の日付フォーマット
  })

  it('filterLocalDataが検索クエリでフィルタする', () => {
    const { result } = renderHook(() => useFilters())
    
    const mockData: RecipeHistory[] = [
      {
        id: 1,
        user_id: 1,
        recipe_id: 1,
        cooked_at: '2025-09-10T12:00:00Z',
        memo: 'カレーを作った',
        rating: 4,
        created_at: '2025-09-10T12:00:00Z',
        updated_at: '2025-09-10T12:00:00Z',
        recipe: {
          id: 1,
          title: 'カレーライス',
          cooking_time: 30,
          difficulty: 'easy'
        }
      },
      {
        id: 2,
        user_id: 1,
        recipe_id: 2,
        cooked_at: '2025-09-09T12:00:00Z',
        memo: 'ハンバーグを作った',
        rating: 5,
        created_at: '2025-09-09T12:00:00Z',
        updated_at: '2025-09-09T12:00:00Z',
        recipe: {
          id: 2,
          title: 'ハンバーグ',
          cooking_time: 45,
          difficulty: 'medium'
        }
      }
    ]
    
    act(() => {
      result.current.setSearchQuery('カレー')
    })
    
    const filteredData = result.current.filterLocalData(mockData)
    
    expect(filteredData).toHaveLength(1)
    expect(filteredData[0].recipe?.title).toBe('カレーライス')
  })

  it('filterLocalDataが未評価フィルタでフィルタする', () => {
    const { result } = renderHook(() => useFilters())
    
    const mockData: RecipeHistory[] = [
      {
        id: 1,
        user_id: 1,
        recipe_id: 1,
        cooked_at: '2025-09-10T12:00:00Z',
        memo: 'メモ1',
        rating: 4,
        created_at: '2025-09-10T12:00:00Z',
        updated_at: '2025-09-10T12:00:00Z'
      },
      {
        id: 2,
        user_id: 1,
        recipe_id: 2,
        cooked_at: '2025-09-09T12:00:00Z',
        memo: 'メモ2',
        rating: null,
        created_at: '2025-09-09T12:00:00Z',
        updated_at: '2025-09-09T12:00:00Z'
      }
    ]
    
    act(() => {
      result.current.setRatedOnly(false) // 未評価のみ
    })
    
    const filteredData = result.current.filterLocalData(mockData)
    
    expect(filteredData).toHaveLength(1)
    expect(filteredData[0].rating).toBe(null)
  })

  it('clearFiltersが全てのフィルタをリセットする', () => {
    const { result } = renderHook(() => useFilters())
    
    act(() => {
      result.current.setPeriod('this-week')
      result.current.setRatedOnly(true)
      result.current.setSearchQuery('テスト')
    })
    
    expect(result.current.hasActiveFilters).toBe(true)
    
    act(() => {
      result.current.clearFilters()
    })
    
    expect(result.current.filters.period).toBe('all')
    expect(result.current.filters.ratedOnly).toBe(null)
    expect(result.current.filters.searchQuery).toBe('')
    expect(result.current.hasActiveFilters).toBe(false)
  })

  it('getApiParamsでrated_onlyパラメータが正しく設定される', () => {
    const { result } = renderHook(() => useFilters())
    
    // 評価済みフィルタ
    act(() => {
      result.current.setRatedOnly(true)
    })
    
    let apiParams = result.current.getApiParams()
    expect(apiParams.rated_only).toBe(true)

    // 未評価フィルタ（サーバーサイド対応時にunrated_onlyが追加される予定）
    act(() => {
      result.current.setRatedOnly(false)
    })
    
    apiParams = result.current.getApiParams()
    expect(apiParams.rated_only).toBeUndefined() // 現在はクライアントサイドフィルタ

    // フィルタなし
    act(() => {
      result.current.setRatedOnly(null)
    })
    
    apiParams = result.current.getApiParams()
    expect(apiParams.rated_only).toBeUndefined()
  })

  it('期間フィルタの日付計算が正確', () => {
    const { result } = renderHook(() => useFilters())
    
    // 今週フィルタ
    act(() => {
      result.current.setPeriod('this-week')
    })
    
    const weekParams = result.current.getApiParams()
    expect(weekParams.start_date).toBeDefined()
    
    // 今月フィルタ
    act(() => {
      result.current.setPeriod('this-month')
    })
    
    const monthParams = result.current.getApiParams()
    expect(monthParams.start_date).toBeDefined()
    expect(monthParams.start_date).toMatch(/^\d{4}-\d{2}-01$/) // 月初の形式

    // 全期間フィルタ
    act(() => {
      result.current.setPeriod('all')
    })
    
    const allParams = result.current.getApiParams()
    expect(allParams.start_date).toBeUndefined()
  })

  it('複数フィルタの組み合わせが正しく動作', () => {
    const { result } = renderHook(() => useFilters())
    
    act(() => {
      result.current.setPeriod('this-month')
      result.current.setRatedOnly(true)
      result.current.setSearchQuery('カレー')
    })
    
    const apiParams = result.current.getApiParams()
    expect(apiParams.start_date).toBeDefined()
    expect(apiParams.rated_only).toBe(true)
    // searchQueryはクライアントサイドのみなのでAPIパラメータには含まれない
    expect(apiParams).not.toHaveProperty('q')
    
    expect(result.current.hasActiveFilters).toBe(true)
  })

  it('filterLocalDataで複合検索が動作する', () => {
    const { result } = renderHook(() => useFilters())
    
    const mockData: RecipeHistory[] = [
      {
        id: 1,
        user_id: 1,
        recipe_id: 1,
        cooked_at: '2025-09-10T12:00:00Z',
        memo: 'カレーを作った',
        rating: 4,
        created_at: '2025-09-10T12:00:00Z',
        updated_at: '2025-09-10T12:00:00Z',
        recipe: {
          id: 1,
          title: 'カレーライス',
          cooking_time: 30,
          difficulty: 'easy'
        }
      },
      {
        id: 2,
        user_id: 1,
        recipe_id: 2,
        cooked_at: '2025-09-09T12:00:00Z',
        memo: 'ハンバーグを作った',
        rating: null,
        created_at: '2025-09-09T12:00:00Z',
        updated_at: '2025-09-09T12:00:00Z',
        recipe: {
          id: 2,
          title: 'ハンバーグ',
          cooking_time: 45,
          difficulty: 'medium'
        }
      },
      {
        id: 3,
        user_id: 1,
        recipe_id: 3,
        cooked_at: '2025-09-08T12:00:00Z',
        memo: '美味しいカレー',
        rating: null,
        created_at: '2025-09-08T12:00:00Z',
        updated_at: '2025-09-08T12:00:00Z',
        recipe: {
          id: 3,
          title: 'スパイスカレー',
          cooking_time: 60,
          difficulty: 'hard'
        }
      }
    ]
    
    // 検索 + 未評価フィルタの組み合わせ
    act(() => {
      result.current.setSearchQuery('カレー')
      result.current.setRatedOnly(false) // 未評価のみ
    })
    
    const filteredData = result.current.filterLocalData(mockData)
    
    expect(filteredData).toHaveLength(1)
    expect(filteredData[0].id).toBe(3) // スパイスカレー（未評価）
    expect(filteredData[0].recipe?.title).toBe('スパイスカレー')
  })
})