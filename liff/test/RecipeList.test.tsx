import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import RecipeList from '../src/pages/Recipes/RecipeList'
import * as recipesApiModule from '../src/api/recipes'

vi.mock('../src/api/recipes', () => ({
  recipesApi: {
    listRecipes: vi.fn(),
  },
}))

const mockRecipesApi = vi.mocked(recipesApiModule.recipesApi)

const Wrapper = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>{children}</BrowserRouter>
)

describe('RecipeList', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('ローディング表示', () => {
    mockRecipesApi.listRecipes.mockImplementation(() => new Promise(() => {}))
    render(<RecipeList />, { wrapper: Wrapper })
    expect(screen.getByText('読み込み中...')).toBeInTheDocument()
  })

  it('レシピがない場合の空表示', async () => {
    mockRecipesApi.listRecipes.mockResolvedValue([])
    render(<RecipeList />, { wrapper: Wrapper })
    await waitFor(() => {
      expect(screen.getByText('レシピが見つかりません')).toBeInTheDocument()
    })
  })

  it('レシピ一覧表示', async () => {
    const now = new Date().toISOString()
    mockRecipesApi.listRecipes.mockResolvedValue([
      {
        id: 1,
        title: 'テストレシピA',
        cooking_time: 10,
        formatted_cooking_time: '10分',
        difficulty: 'easy',
        difficulty_display: '簡単 ⭐',
        servings: 1,
        created_at: now,
      },
      {
        id: 2,
        title: 'テストレシピB',
        cooking_time: 30,
        formatted_cooking_time: '30分',
        difficulty: 'medium',
        difficulty_display: '普通 ⭐⭐',
        servings: 2,
        created_at: now,
      },
    ])

    render(<RecipeList />, { wrapper: Wrapper })

    await waitFor(() => {
      expect(screen.getByText('テストレシピA')).toBeInTheDocument()
      expect(screen.getByText('テストレシピB')).toBeInTheDocument()
      expect(screen.getByText('⏱ 10分')).toBeInTheDocument()
      expect(screen.getByText('普通 ⭐⭐')).toBeInTheDocument()
      expect(screen.getByText('👥 2人分')).toBeInTheDocument()
    })
  })
})

