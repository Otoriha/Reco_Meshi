import { render, screen } from '@testing-library/react'
import React from 'react'
import IngredientCard from '../../../src/components/ingredients/IngredientCard'

const baseItem = {
  id: 1,
  user_id: 1,
  ingredient_id: 10,
  quantity: 1,
  status: 'available' as const,
  expiry_date: null,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-02T00:00:00Z',
  ingredient: { id: 10, name: '牛乳', category: 'dairy', unit: '本', emoji: '🥛' },
  display_name: '牛乳',
  formatted_quantity: '1本',
  days_until_expiry: null,
  expired: false,
  expiring_soon: false,
}

describe('IngredientCard', () => {
  it('renders name and quantity', () => {
    render(<IngredientCard item={baseItem} />)
    expect(screen.getByText(/牛乳/)).toBeInTheDocument()
    expect(screen.getByText('1本')).toBeInTheDocument()
  })

  it('shows red background when expired', () => {
    const item = { ...baseItem, expired: true }
    const { container } = render(<IngredientCard item={item} />)
    // style class check
    expect(container.firstChild).toHaveClass('bg-red-50')
  })
})

