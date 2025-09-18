import { describe, it, expect, vi, beforeEach } from 'vitest'
import { recipesApi } from '../src/api/recipes'
import { apiClient } from '../src/api/client'

vi.mock('../src/api/client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

const mockApiClient = vi.mocked(apiClient)

describe('recipes API', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('listRecipes: 一覧を取得し成功時にデータを返す', async () => {
    const mockData = [
      {
        id: 1,
        title: 'テストレシピ',
        cooking_time: 15,
        formatted_cooking_time: '15分',
        difficulty: 'easy',
        difficulty_display: '簡単 ⭐',
        servings: 1,
        created_at: new Date().toISOString(),
      },
    ]
    mockApiClient.get.mockResolvedValueOnce({ data: { success: true, data: mockData } })

    const result = await recipesApi.listRecipes()
    expect(mockApiClient.get).toHaveBeenCalledWith('/recipes')
    expect(result).toEqual(mockData)
  })

  it('getRecipe: 詳細を取得し成功時にデータを返す', async () => {
    const mockRecipe = {
      id: 1,
      title: 'テストレシピ',
      cooking_time: 15,
      formatted_cooking_time: '15分',
      difficulty: 'easy' as const,
      difficulty_display: '簡単 ⭐',
      servings: 1,
      created_at: new Date().toISOString(),
      steps: ['手順1', '手順2'],
      ingredients: [
        { id: 10, name: 'にんじん', amount: 1, unit: '本', is_optional: false },
      ],
    }
    mockApiClient.get.mockResolvedValueOnce({ data: { success: true, data: mockRecipe } })

    const result = await recipesApi.getRecipe(1)
    expect(mockApiClient.get).toHaveBeenCalledWith('/recipes/1')
    expect(result).toEqual(mockRecipe)
  })

  it('listRecipeHistories: 履歴一覧を取得', async () => {
    const mockHistories = [
      {
        id: 1,
        user_id: 1,
        recipe_id: 1,
        cooked_at: new Date().toISOString(),
        memo: 'テスト',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
    ]
    mockApiClient.get.mockResolvedValueOnce({ data: { success: true, data: mockHistories } })

    const result = await recipesApi.listRecipeHistories()
    expect(mockApiClient.get).toHaveBeenCalledWith('/recipe_histories')
    expect(result).toEqual(mockHistories)
  })

  it('createRecipeHistory: 履歴を作成', async () => {
    const mockHistory = {
      id: 1,
      user_id: 1,
      recipe_id: 1,
      cooked_at: new Date().toISOString(),
      memo: 'また作りたい',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }
    mockApiClient.post.mockResolvedValueOnce({ data: { success: true, data: mockHistory } })

    const result = await recipesApi.createRecipeHistory({ recipe_id: 1, memo: 'また作りたい' })
    expect(mockApiClient.post).toHaveBeenCalledWith('/recipe_histories', { recipe_history: { recipe_id: 1, memo: 'また作りたい' } })
    expect(result).toEqual(mockHistory)
  })

  it('APIのsuccess=false時はエラーを投げる', async () => {
    mockApiClient.get.mockResolvedValueOnce({ data: { success: false, data: [] } })
    await expect(recipesApi.listRecipes()).rejects.toThrow()
  })
})