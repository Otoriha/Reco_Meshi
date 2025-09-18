import { render, screen, waitFor } from '@testing-library/react'
import React from 'react'
import Ingredients from '../../src/pages/Ingredients/Ingredients'
import { BrowserRouter } from 'react-router-dom'

vi.mock('../../src/api/userIngredients', () => ({
  getUserIngredients: vi.fn((params: Record<string, unknown> = {}) => {
    if (params.group_by === 'category') {
      return Promise.resolve({
        status: { code: 200, message: 'OK' },
        data: {
          vegetables: [
            {
              id: 1,
              user_id: 1,
              ingredient_id: 10,
              quantity: 2,
              status: 'available',
              expiry_date: '2099-01-01',
              created_at: '2025-01-01T00:00:00Z',
              updated_at: '2025-01-02T00:00:00Z',
              ingredient: { id: 10, name: 'にんじん', category: 'vegetables', unit: '本', emoji: '🥕' },
              display_name: 'にんじん',
              formatted_quantity: '2本',
              days_until_expiry: 10,
              expired: false,
              expiring_soon: false,
            },
          ],
        },
      })
    }
    return Promise.resolve({
      status: { code: 200, message: 'OK' },
      data: [],
    })
  }),
  createUserIngredient: vi.fn(),
  updateUserIngredient: vi.fn(),
  deleteUserIngredient: vi.fn(),
}))

describe('Ingredients Page', () => {
  it('renders and shows grouped list after loading', async () => {
    render(
      <BrowserRouter>
        <Ingredients />
      </BrowserRouter>
    )

    // Loading state
    expect(screen.getByText('読み込み中...')).toBeInTheDocument()

    // After load
    await waitFor(() => {
      expect(screen.getByText('食材リスト')).toBeInTheDocument()
      // Check for category heading (not the select option)
      expect(screen.getByRole('heading', { name: '野菜' })).toBeInTheDocument()
      expect(screen.getByText(/にんじん/)).toBeInTheDocument()
    })
  })
})

