import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import RecipeHistoryModal from '../src/pages/RecipeHistory/RecipeHistoryModal'
import type { RecipeHistory } from '../src/types/recipe'

const mockHistory: RecipeHistory = {
  id: 1,
  user_id: 1,
  recipe_id: 1,
  cooked_at: '2025-09-10T12:00:00Z',
  memo: 'とても美味しかった',
  rating: 4,
  created_at: '2025-09-10T12:00:00Z',
  updated_at: '2025-09-10T12:00:00Z',
  recipe: {
    id: 1,
    title: 'カレーライス',
    cooking_time: 30,
    difficulty: 'easy'
  }
}

const defaultProps = {
  history: mockHistory,
  isOpen: true,
  onClose: vi.fn(),
  onUpdate: vi.fn(),
  onDelete: vi.fn()
}

const renderWithRouter = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      {component}
    </BrowserRouter>
  )
}

describe('RecipeHistoryModal', () => {
  it('モーダルが正しくレンダリングされる', () => {
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    expect(screen.getByText('カレーライス')).toBeInTheDocument()
    expect(screen.getByText('とても美味しかった')).toBeInTheDocument()
    expect(screen.getByText('評価')).toBeInTheDocument()
    expect(screen.getByText('メモ')).toBeInTheDocument()
  })

  it('モーダルが閉じている時は何も表示されない', () => {
    const props = { ...defaultProps, isOpen: false }
    renderWithRouter(<RecipeHistoryModal {...props} />)
    
    expect(screen.queryByText('カレーライス')).not.toBeInTheDocument()
  })

  it('historyがnullの時は何も表示されない', () => {
    const props = { ...defaultProps, history: null }
    renderWithRouter(<RecipeHistoryModal {...props} />)
    
    expect(screen.queryByText('カレーライス')).not.toBeInTheDocument()
  })

  it('閉じるボタンが正しく動作する', () => {
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    const closeButton = screen.getByText('✕')
    fireEvent.click(closeButton)
    
    expect(defaultProps.onClose).toHaveBeenCalled()
  })

  it('星評価が正しく表示される', () => {
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    const stars = screen.getAllByText('★')
    // 5つの星が表示される（評価用）
    expect(stars).toHaveLength(5)
  })

  it('星をクリックして評価を変更できる', () => {
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    const stars = screen.getAllByText('★')
    fireEvent.click(stars[4]) // 5番目の星をクリック（5点評価）
    
    // 変更を保存ボタンが表示される
    expect(screen.getByText('変更を保存')).toBeInTheDocument()
  })

  it('メモを編集できる', () => {
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    const memoTextarea = screen.getByDisplayValue('とても美味しかった')
    fireEvent.change(memoTextarea, { target: { value: '新しいメモ' } })
    
    // 変更を保存ボタンが表示される
    expect(screen.getByText('変更を保存')).toBeInTheDocument()
  })

  it('変更を保存ボタンが正しく動作する', async () => {
    defaultProps.onUpdate.mockResolvedValue(undefined)
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    // 評価を変更
    const stars = screen.getAllByText('★')
    fireEvent.click(stars[4])
    
    // 保存ボタンをクリック
    const saveButton = screen.getByText('変更を保存')
    fireEvent.click(saveButton)
    
    await waitFor(() => {
      expect(defaultProps.onUpdate).toHaveBeenCalledWith(1, { rating: 5 })
    })
  })

  it('削除ボタンと確認ダイアログが正しく動作する', async () => {
    defaultProps.onDelete.mockResolvedValue(undefined)
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    // 削除ボタンをクリック
    const deleteButton = screen.getByText('この記録を削除')
    fireEvent.click(deleteButton)
    
    // 確認ダイアログが表示される
    expect(screen.getByText('本当に削除しますか？')).toBeInTheDocument()
    
    // 削除実行
    const confirmButton = screen.getByText('削除')
    fireEvent.click(confirmButton)
    
    await waitFor(() => {
      expect(defaultProps.onDelete).toHaveBeenCalledWith(1)
    })
  })

  it('削除確認でキャンセルできる', () => {
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    // 削除ボタンをクリック
    const deleteButton = screen.getByText('この記録を削除')
    fireEvent.click(deleteButton)
    
    // キャンセルボタンをクリック
    const cancelButton = screen.getByText('キャンセル')
    fireEvent.click(cancelButton)
    
    // 確認ダイアログが非表示になる
    expect(screen.queryByText('本当に削除しますか？')).not.toBeInTheDocument()
    expect(screen.getByText('この記録を削除')).toBeInTheDocument()
  })

  it('レシピ詳細へのリンクが正しく表示される', () => {
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    const recipeLink = screen.getByText('レシピを見る →')
    expect(recipeLink).toHaveAttribute('href', '/recipes/1')
  })

  it('変更がない場合は保存ボタンが表示されない', () => {
    renderWithRouter(<RecipeHistoryModal {...defaultProps} />)
    
    expect(screen.queryByText('変更を保存')).not.toBeInTheDocument()
  })
})