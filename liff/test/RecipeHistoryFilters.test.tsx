import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import RecipeHistoryFilters from '../src/pages/RecipeHistory/RecipeHistoryFilters'
import type { FilterPeriod } from '../src/hooks/useFilters'

const mockFilters = {
  period: 'all' as FilterPeriod,
  ratedOnly: null,
  searchQuery: ''
}

const mockProps = {
  filters: mockFilters,
  setPeriod: vi.fn(),
  setRatedOnly: vi.fn(),
  setSearchQuery: vi.fn(),
  hasActiveFilters: false,
  clearFilters: vi.fn()
}

describe('RecipeHistoryFilters', () => {
  it('フィルタコンポーネントが正しくレンダリングされる', () => {
    render(<RecipeHistoryFilters {...mockProps} />)
    
    expect(screen.getByText('フィルタ')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('レシピ名やメモで検索')).toBeInTheDocument()
    expect(screen.getByText('期間')).toBeInTheDocument()
    expect(screen.getByText('評価')).toBeInTheDocument()
  })

  it('検索入力が正しく動作する', () => {
    render(<RecipeHistoryFilters {...mockProps} />)
    
    const searchInput = screen.getByPlaceholderText('レシピ名やメモで検索')
    fireEvent.change(searchInput, { target: { value: 'カレー' } })
    
    expect(mockProps.setSearchQuery).toHaveBeenCalledWith('カレー')
  })

  it('期間フィルタボタンが正しく動作する', () => {
    render(<RecipeHistoryFilters {...mockProps} />)
    
    const weekButton = screen.getByText('今週')
    fireEvent.click(weekButton)
    
    expect(mockProps.setPeriod).toHaveBeenCalledWith('this-week')
  })

  it('評価フィルタボタンが正しく動作する', () => {
    render(<RecipeHistoryFilters {...mockProps} />)
    
    const ratedButton = screen.getByText('評価済み')
    fireEvent.click(ratedButton)
    
    expect(mockProps.setRatedOnly).toHaveBeenCalledWith(true)
  })

  it('アクティブフィルタがある時にクリアボタンが表示される', () => {
    const propsWithActiveFilters = {
      ...mockProps,
      hasActiveFilters: true
    }
    
    render(<RecipeHistoryFilters {...propsWithActiveFilters} />)
    
    const clearButton = screen.getByText('クリア')
    expect(clearButton).toBeInTheDocument()
    
    fireEvent.click(clearButton)
    expect(mockProps.clearFilters).toHaveBeenCalled()
  })

  it('アクティブフィルタがない時にクリアボタンが非表示になる', () => {
    render(<RecipeHistoryFilters {...mockProps} />)
    
    expect(screen.queryByText('クリア')).not.toBeInTheDocument()
  })

  it('選択された期間フィルタにアクティブスタイルが適用される', () => {
    const propsWithSelectedPeriod = {
      ...mockProps,
      filters: { ...mockFilters, period: 'this-week' as FilterPeriod }
    }
    
    render(<RecipeHistoryFilters {...propsWithSelectedPeriod} />)
    
    const weekButton = screen.getByText('今週')
    expect(weekButton).toHaveClass('bg-blue-500', 'text-white')
  })
})