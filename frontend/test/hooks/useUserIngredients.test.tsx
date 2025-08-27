import { render, waitFor } from '@testing-library/react'
import React from 'react'
import { useUserIngredients } from '../../src/hooks/useUserIngredients'

vi.mock('../../src/api/userIngredients', () => ({
  getUserIngredients: vi.fn(() => Promise.resolve({
    status: { code: 200, message: 'OK' },
    data: [
      {
        id: 1,
        user_id: 1,
        ingredient_id: 10,
        quantity: 1,
        status: 'available',
        expiry_date: null,
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-02T00:00:00Z',
        ingredient: { id: 10, name: 'たまねぎ', category: 'vegetables', unit: '個', emoji: '🧅' },
        display_name: 'たまねぎ',
        formatted_quantity: '1個',
        days_until_expiry: null,
        expired: false,
        expiring_soon: false,
      },
      {
        id: 2,
        user_id: 1,
        ingredient_id: 20,
        quantity: 2,
        status: 'available',
        expiry_date: null,
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-03T00:00:00Z',
        ingredient: { id: 20, name: 'にんじん', category: 'vegetables', unit: '本', emoji: '🥕' },
        display_name: 'にんじん',
        formatted_quantity: '2本',
        days_until_expiry: null,
        expired: false,
        expiring_soon: false,
      },
    ],
  })),
}))

const TestComp: React.FC = () => {
  const { items, setFilters, filters } = useUserIngredients('none')
  React.useEffect(() => {
    setFilters({ ...filters, name: 'にん' })
  }, [])
  return <div data-testid="count">{items.length}</div>
}

describe('useUserIngredients hook', () => {
  it('filters by name on client side', async () => {
    const { getByTestId } = render(<TestComp />)
    await waitFor(() => {
      // たまねぎは除外、にんじんのみ
      expect(getByTestId('count').textContent).toBe('1')
    })
  })
})

