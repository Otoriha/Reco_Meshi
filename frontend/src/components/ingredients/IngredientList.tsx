import React from 'react'
import type { UserIngredient } from '../../types/ingredient'
import IngredientCard from './IngredientCard'
import { CATEGORY_LABELS } from '../../constants/categories'

type Props = {
  groupBy: 'none' | 'category'
  items: UserIngredient[]
  groups: Record<string, UserIngredient[]>
  onEdit: (item: UserIngredient) => void
  onDelete: (item: UserIngredient) => void
}

const IngredientList: React.FC<Props> = ({ groupBy, items, groups, onEdit, onDelete }) => {
  if (groupBy === 'category') {
    const keys = Object.keys(groups)
    if (keys.length === 0) return <p className="text-gray-600">食材がありません。</p>
    return (
      <div className="space-y-8">
        {keys.sort().map((category) => (
          <div key={category}>
            <h2 className="text-xl font-semibold text-gray-700 mb-4">
              {CATEGORY_LABELS[category] || category || 'その他'}
            </h2>
            <div className="grid grid-cols-1 gap-4">
              {(groups[category] || []).map((item) => (
                <IngredientCard key={item.id} item={item} onEdit={onEdit} onDelete={onDelete} />
              ))}
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (items.length === 0) return <p className="text-gray-600">食材がありません。</p>
  return (
    <div className="grid grid-cols-1 gap-4">
      {items.map((item) => (
        <IngredientCard key={item.id} item={item} onEdit={onEdit} onDelete={onDelete} />
      ))}
    </div>
  )
}

export default IngredientList

