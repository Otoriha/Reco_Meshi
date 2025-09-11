import { render, act } from '@testing-library/react'
import React from 'react'
import { useFilters } from '../../src/hooks/useFilters'
import type { RecipeHistory } from '../../src/types/recipe'

// モックデータ
const mockHistory1: RecipeHistory = {
  id: 1,
  user_id: 1,
  recipe_id: 10,
  cooked_at: '2025-01-15T12:00:00Z',
  memo: 'おいしかった',
  rating: 5,
  created_at: '2025-01-15T12:00:00Z',
  updated_at: '2025-01-15T12:00:00Z',
  recipe: {
    id: 10,
    title: 'カレーライス',
    cooking_time: 30,
    difficulty: 'easy'
  }
}

const mockHistory2: RecipeHistory = {
  id: 2,
  user_id: 1,
  recipe_id: 20,
  cooked_at: '2025-01-14T18:00:00Z',
  memo: null,
  rating: null,
  created_at: '2025-01-14T18:00:00Z',
  updated_at: '2025-01-14T18:00:00Z',
  recipe: {
    id: 20,
    title: '野菜炒め',
    cooking_time: 15,
    difficulty: 'easy'
  }
}

const mockHistory3: RecipeHistory = {
  id: 3,
  user_id: 1,
  recipe_id: 30,
  cooked_at: '2025-01-13T18:00:00Z',
  memo: '野菜がシャキシャキ',
  rating: 4,
  created_at: '2025-01-13T18:00:00Z',
  updated_at: '2025-01-13T18:00:00Z',
  recipe: {
    id: 30,
    title: 'サラダ',
    cooking_time: 5,
    difficulty: 'easy'
  }
}

const TestComponent: React.FC = () => {
  const {
    filters,
    setPeriod,
    setRatedOnly,
    setSearchQuery,
    getApiParams,
    filterLocalData,
    hasActiveFilters,
    clearFilters
  } = useFilters()

  const testData = [mockHistory1, mockHistory2, mockHistory3]
  const filteredData = filterLocalData(testData)
  const apiParams = getApiParams()

  return (
    <div>
      <div data-testid="period">{filters.period}</div>
      <div data-testid="rated-only">{String(filters.ratedOnly)}</div>
      <div data-testid="search-query">{filters.searchQuery}</div>
      <div data-testid="has-active-filters">{String(hasActiveFilters)}</div>
      <div data-testid="filtered-count">{filteredData.length}</div>
      <div data-testid="api-params">{JSON.stringify(apiParams)}</div>
      
      <button 
        data-testid="set-period-week" 
        onClick={() => setPeriod('this-week')}
      >
        This Week
      </button>
      <button 
        data-testid="set-period-month" 
        onClick={() => setPeriod('this-month')}
      >
        This Month
      </button>
      <button 
        data-testid="set-rated-only-true" 
        onClick={() => setRatedOnly(true)}
      >
        Rated Only True
      </button>
      <button 
        data-testid="set-rated-only-false" 
        onClick={() => setRatedOnly(false)}
      >
        Rated Only False
      </button>
      <button 
        data-testid="set-search-query" 
        onClick={() => setSearchQuery('カレー')}
      >
        Search Curry
      </button>
      <button 
        data-testid="clear-filters" 
        onClick={() => clearFilters()}
      >
        Clear Filters
      </button>
    </div>
  )
}

describe('useFilters hook', () => {
  it('初期状態が正しく設定される', () => {
    const { getByTestId } = render(<TestComponent />)
    
    expect(getByTestId('period').textContent).toBe('all')
    expect(getByTestId('rated-only').textContent).toBe('null')
    expect(getByTestId('search-query').textContent).toBe('')
    expect(getByTestId('has-active-filters').textContent).toBe('false')
    expect(getByTestId('filtered-count').textContent).toBe('3')
    expect(getByTestId('api-params').textContent).toBe('{}')
  })

  it('期間フィルタが正しく動作する', () => {
    const { getByTestId } = render(<TestComponent />)
    
    act(() => {
      getByTestId('set-period-week').click()
    })
    
    expect(getByTestId('period').textContent).toBe('this-week')
    expect(getByTestId('has-active-filters').textContent).toBe('true')
    
    // APIパラメータにstart_dateが含まれることを確認
    const apiParams = JSON.parse(getByTestId('api-params').textContent || '{}')
    expect(apiParams).toHaveProperty('start_date')
  })

  it('月間フィルタが正しく動作する', () => {
    const { getByTestId } = render(<TestComponent />)
    
    act(() => {
      getByTestId('set-period-month').click()
    })
    
    expect(getByTestId('period').textContent).toBe('this-month')
    expect(getByTestId('has-active-filters').textContent).toBe('true')
    
    // APIパラメータにstart_dateが含まれることを確認
    const apiParams = JSON.parse(getByTestId('api-params').textContent || '{}')
    expect(apiParams).toHaveProperty('start_date')
  })

  it('評価フィルタが正しく動作する（評価済みのみ）', () => {
    const { getByTestId } = render(<TestComponent />)
    
    act(() => {
      getByTestId('set-rated-only-true').click()
    })
    
    expect(getByTestId('rated-only').textContent).toBe('true')
    expect(getByTestId('has-active-filters').textContent).toBe('true')
    
    // APIパラメータにrated_onlyが含まれることを確認
    const apiParams = JSON.parse(getByTestId('api-params').textContent || '{}')
    expect(apiParams.rated_only).toBe(true)
  })

  it('評価フィルタが正しく動作する（未評価のみ）', () => {
    const { getByTestId } = render(<TestComponent />)
    
    act(() => {
      getByTestId('set-rated-only-false').click()
    })
    
    expect(getByTestId('rated-only').textContent).toBe('false')
    expect(getByTestId('has-active-filters').textContent).toBe('true')
    
    // クライアントサイドフィルタで未評価のもののみが残る（mockHistory2のみ）
    expect(getByTestId('filtered-count').textContent).toBe('1')
    
    // APIパラメータにrated_onlyは含まれない（false）
    const apiParams = JSON.parse(getByTestId('api-params').textContent || '{}')
    expect(apiParams.rated_only).toBeUndefined()
  })

  it('検索フィルタが正しく動作する', () => {
    const { getByTestId } = render(<TestComponent />)
    
    act(() => {
      getByTestId('set-search-query').click()
    })
    
    expect(getByTestId('search-query').textContent).toBe('カレー')
    expect(getByTestId('has-active-filters').textContent).toBe('true')
    
    // クライアントサイドフィルタでカレーライスのみが残る
    expect(getByTestId('filtered-count').textContent).toBe('1')
  })

  it('メモでの検索が正しく動作する', () => {
    const TestComponentWithMemoSearch: React.FC = () => {
      const { setSearchQuery, filterLocalData } = useFilters()
      
      React.useEffect(() => {
        setSearchQuery('野菜')
      }, [setSearchQuery])
      
      const testData = [mockHistory1, mockHistory2, mockHistory3]
      const filteredData = filterLocalData(testData)
      
      return <div data-testid="memo-filtered-count">{filteredData.length}</div>
    }
    
    const { getByTestId } = render(<TestComponentWithMemoSearch />)
    
    // メモに「野菜」が含まれるmockHistory3が該当
    expect(getByTestId('memo-filtered-count').textContent).toBe('1')
  })

  it('フィルタをクリアできる', () => {
    const { getByTestId } = render(<TestComponent />)
    
    // フィルタを設定
    act(() => {
      getByTestId('set-period-week').click()
    })
    act(() => {
      getByTestId('set-rated-only-true').click()
    })
    act(() => {
      getByTestId('set-search-query').click()
    })
    
    expect(getByTestId('has-active-filters').textContent).toBe('true')
    
    // フィルタをクリア
    act(() => {
      getByTestId('clear-filters').click()
    })
    
    expect(getByTestId('period').textContent).toBe('all')
    expect(getByTestId('rated-only').textContent).toBe('null')
    expect(getByTestId('search-query').textContent).toBe('')
    expect(getByTestId('has-active-filters').textContent).toBe('false')
    expect(getByTestId('filtered-count').textContent).toBe('3')
  })

  it('複数のフィルタが組み合わせて動作する', () => {
    const TestComponentWithMultipleFilters: React.FC = () => {
      const { setRatedOnly, setSearchQuery, filterLocalData } = useFilters()
      
      React.useEffect(() => {
        setRatedOnly(true) // 評価済みのみ
        setSearchQuery('サ') // サで始まる（サラダ）
      }, [setRatedOnly, setSearchQuery])
      
      const testData = [mockHistory1, mockHistory2, mockHistory3]
      const filteredData = filterLocalData(testData)
      
      return <div data-testid="multi-filtered-count">{filteredData.length}</div>
    }
    
    const { getByTestId } = render(<TestComponentWithMultipleFilters />)
    
    // 評価済み（mockHistory1, mockHistory3）かつサで始まる（mockHistory3のみ）
    expect(getByTestId('multi-filtered-count').textContent).toBe('1')
  })
})