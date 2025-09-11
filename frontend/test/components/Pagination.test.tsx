import { render, fireEvent } from '@testing-library/react'
import React from 'react'
import Pagination from '../../src/components/Pagination'

const mockOnPageChange = vi.fn()

describe('Pagination Component', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('総ページ数が1の場合は何も表示しない', () => {
    const { container } = render(
      <Pagination
        currentPage={1}
        totalPages={1}
        onPageChange={mockOnPageChange}
      />
    )
    
    expect(container.firstChild).toBeNull()
  })

  it('基本的なページネーションが正しく表示される', () => {
    const { getByText } = render(
      <Pagination
        currentPage={2}
        totalPages={5}
        onPageChange={mockOnPageChange}
      />
    )
    
    expect(getByText('前へ')).toBeInTheDocument()
    expect(getByText('次へ')).toBeInTheDocument()
    expect(getByText('1')).toBeInTheDocument()
    expect(getByText('2')).toBeInTheDocument()
    expect(getByText('3')).toBeInTheDocument()
    expect(getByText('4')).toBeInTheDocument()
    expect(getByText('5')).toBeInTheDocument()
  })

  it('現在のページが正しくハイライトされる', () => {
    const { getByText } = render(
      <Pagination
        currentPage={3}
        totalPages={5}
        onPageChange={mockOnPageChange}
      />
    )
    
    const currentPageButton = getByText('3')
    expect(currentPageButton).toHaveClass('text-blue-600', 'bg-blue-50', 'border-blue-300')
  })

  it('前へボタンが正しく動作する', () => {
    const { getByText } = render(
      <Pagination
        currentPage={3}
        totalPages={5}
        onPageChange={mockOnPageChange}
      />
    )
    
    const prevButton = getByText('前へ')
    fireEvent.click(prevButton)
    
    expect(mockOnPageChange).toHaveBeenCalledWith(2)
  })

  it('次へボタンが正しく動作する', () => {
    const { getByText } = render(
      <Pagination
        currentPage={3}
        totalPages={5}
        onPageChange={mockOnPageChange}
      />
    )
    
    const nextButton = getByText('次へ')
    fireEvent.click(nextButton)
    
    expect(mockOnPageChange).toHaveBeenCalledWith(4)
  })

  it('ページ番号ボタンが正しく動作する', () => {
    const { getByText } = render(
      <Pagination
        currentPage={2}
        totalPages={5}
        onPageChange={mockOnPageChange}
      />
    )
    
    const pageButton = getByText('4')
    fireEvent.click(pageButton)
    
    expect(mockOnPageChange).toHaveBeenCalledWith(4)
  })

  it('最初のページで前へボタンが無効になる', () => {
    const { getByText } = render(
      <Pagination
        currentPage={1}
        totalPages={5}
        onPageChange={mockOnPageChange}
      />
    )
    
    const prevButton = getByText('前へ')
    expect(prevButton).toBeDisabled()
  })

  it('最後のページで次へボタンが無効になる', () => {
    const { getByText } = render(
      <Pagination
        currentPage={5}
        totalPages={5}
        onPageChange={mockOnPageChange}
      />
    )
    
    const nextButton = getByText('次へ')
    expect(nextButton).toBeDisabled()
  })

  it('ローディング中はすべてのボタンが無効になる', () => {
    const { getByText } = render(
      <Pagination
        currentPage={3}
        totalPages={5}
        onPageChange={mockOnPageChange}
        loading={true}
      />
    )
    
    expect(getByText('前へ')).toBeDisabled()
    expect(getByText('次へ')).toBeDisabled()
    expect(getByText('1')).toBeDisabled()
    expect(getByText('2')).toBeDisabled()
  })

  it('多数のページがある場合に省略記号が表示される', () => {
    const { getAllByText, getByText, queryByText } = render(
      <Pagination
        currentPage={5}
        totalPages={20}
        onPageChange={mockOnPageChange}
      />
    )
    
    // 最初のページは表示
    expect(getByText('1')).toBeInTheDocument()
    
    // 省略記号が表示される（複数ある場合がある）
    const ellipsis = getAllByText('...')
    expect(ellipsis.length).toBeGreaterThan(0)
    
    // 現在のページ周辺は表示
    expect(getByText('3')).toBeInTheDocument()
    expect(getByText('4')).toBeInTheDocument()
    expect(getByText('5')).toBeInTheDocument()
    expect(getByText('6')).toBeInTheDocument()
    expect(getByText('7')).toBeInTheDocument()
    
    // 最後のページは表示
    expect(getByText('20')).toBeInTheDocument()
    
    // 中間のページは表示されない
    expect(queryByText('10')).not.toBeInTheDocument()
  })

  it('最初の方のページにいる場合の表示が正しい', () => {
    const { getByText, queryByText } = render(
      <Pagination
        currentPage={2}
        totalPages={20}
        onPageChange={mockOnPageChange}
      />
    )
    
    // 最初の方のページは連続して表示
    expect(getByText('1')).toBeInTheDocument()
    expect(getByText('2')).toBeInTheDocument()
    expect(getByText('3')).toBeInTheDocument()
    expect(getByText('4')).toBeInTheDocument()
    
    // 省略記号
    expect(getByText('...')).toBeInTheDocument()
    
    // 最後のページ
    expect(getByText('20')).toBeInTheDocument()
    
    // 中間は表示されない
    expect(queryByText('10')).not.toBeInTheDocument()
  })

  it('最後の方のページにいる場合の表示が正しい', () => {
    const { getByText, queryByText } = render(
      <Pagination
        currentPage={19}
        totalPages={20}
        onPageChange={mockOnPageChange}
      />
    )
    
    // 最初のページ
    expect(getByText('1')).toBeInTheDocument()
    
    // 省略記号
    expect(getByText('...')).toBeInTheDocument()
    
    // 最後の方のページは連続して表示
    expect(getByText('17')).toBeInTheDocument()
    expect(getByText('18')).toBeInTheDocument()
    expect(getByText('19')).toBeInTheDocument()
    expect(getByText('20')).toBeInTheDocument()
    
    // 中間は表示されない
    expect(queryByText('10')).not.toBeInTheDocument()
  })

  it('5ページ以下の場合は省略記号なしですべて表示される', () => {
    const { getByText, queryByText } = render(
      <Pagination
        currentPage={3}
        totalPages={5}
        onPageChange={mockOnPageChange}
      />
    )
    
    expect(getByText('1')).toBeInTheDocument()
    expect(getByText('2')).toBeInTheDocument()
    expect(getByText('3')).toBeInTheDocument()
    expect(getByText('4')).toBeInTheDocument()
    expect(getByText('5')).toBeInTheDocument()
    expect(queryByText('...')).not.toBeInTheDocument()
  })
})