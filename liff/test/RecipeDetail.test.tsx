import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import RecipeDetail from '../src/pages/Recipes/RecipeDetail'
import * as recipesApiModule from '../src/api/recipes'

vi.mock('../src/api/recipes', () => ({
  recipesApi: {
    getRecipe: vi.fn(),
    createRecipeHistory: vi.fn(),
  },
}))

const mockRecipesApi = vi.mocked(recipesApiModule.recipesApi)

const renderWithRoute = (ui: React.ReactNode, initialPath = '/recipes/1') => {
  return render(
    <MemoryRouter initialEntries={[initialPath]}>
      <Routes>
        <Route path="/recipes/:id" element={ui} />
      </Routes>
    </MemoryRouter>
  )
}

describe('RecipeDetail', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // alertのモック
    vi.spyOn(window, 'alert').mockImplementation(() => {})
  })

  it('ローディング表示', () => {
    mockRecipesApi.getRecipe.mockImplementation(() => new Promise(() => {}))
    renderWithRoute(<RecipeDetail />)
    expect(screen.getByText('読み込み中...')).toBeInTheDocument()
  })

  it('詳細表示と材料チェックの切り替え', async () => {
    mockRecipesApi.getRecipe.mockResolvedValue({
      id: 1,
      title: '煮物',
      cooking_time: 20,
      formatted_cooking_time: '20分',
      difficulty: 'easy',
      difficulty_display: '簡単 ⭐',
      servings: 2,
      created_at: new Date().toISOString(),
      steps: ['切る', '煮る'],
      ingredients: [
        { id: 11, name: '大根', amount: 200, unit: 'g', is_optional: false },
        { id: 12, name: 'しょうゆ', amount: null, unit: null, is_optional: true },
      ],
    })

    renderWithRoute(<RecipeDetail />)

    await waitFor(() => {
      expect(screen.getByText('煮物')).toBeInTheDocument()
      expect(screen.getByText('材料')).toBeInTheDocument()
      expect(screen.getByText('調理手順')).toBeInTheDocument()
    })

    const checkbox = screen.getAllByRole('checkbox')[0]
    // 初期は未チェック
    expect(checkbox).not.toBeChecked()
    fireEvent.click(checkbox)
    expect(checkbox).toBeChecked()
  })

  it('「作った！」で履歴作成APIが呼ばれる', async () => {
    mockRecipesApi.getRecipe.mockResolvedValue({
      id: 1,
      title: 'テスト',
      cooking_time: 10,
      formatted_cooking_time: '10分',
      difficulty: 'easy',
      difficulty_display: '簡単 ⭐',
      servings: 1,
      created_at: new Date().toISOString(),
      steps: ['手順'],
      ingredients: [],
    })
    mockRecipesApi.createRecipeHistory.mockResolvedValue({
      id: 1,
      user_id: 1,
      recipe_id: 1,
      cooked_at: new Date().toISOString(),
      memo: 'メモ',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    } as any)

    renderWithRoute(<RecipeDetail />)

    await waitFor(() => {
      expect(screen.getByText('テスト')).toBeInTheDocument()
    })

    const textarea = screen.getByPlaceholderText('作った感想や工夫した点などを記録できます')
    fireEvent.change(textarea, { target: { value: 'メモ' } })

    const button = screen.getByRole('button', { name: '🍽 作った！' })
    fireEvent.click(button)

    await waitFor(() => {
      expect(mockRecipesApi.createRecipeHistory).toHaveBeenCalledWith({ recipe_id: 1, memo: 'メモ' })
      expect(window.alert).toHaveBeenCalled()
    })
  })
})

