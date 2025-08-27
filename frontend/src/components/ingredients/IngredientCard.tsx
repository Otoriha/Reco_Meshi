import React from 'react'
import type { UserIngredient } from '../../types/ingredient'

type Props = {
  item: UserIngredient
  onEdit?: (item: UserIngredient) => void
  onDelete?: (item: UserIngredient) => void
}

const IngredientCard: React.FC<Props> = ({ item, onEdit, onDelete }) => {
  const isExpired = item.expired
  const isSoon = item.expiring_soon
  const bg = isExpired
    ? 'bg-red-50 border-red-200'
    : isSoon
    ? 'bg-yellow-50 border-yellow-200'
    : 'bg-gray-50 border-gray-200'
  const name = item.ingredient?.name || item.display_name
  const emoji = item.ingredient?.emoji || ''

  return (
    <div className={`border ${bg} rounded p-4 flex items-center justify-between`}> 
      <div>
        <div className="text-gray-800 font-medium">{emoji} {name}</div>
        <div className="text-sm text-gray-600 mt-1">
          {item.days_until_expiry != null ? (
            <span>期限まで {item.days_until_expiry} 日</span>
          ) : (
            <span>期限未設定</span>
          )}
        </div>
      </div>

      <div className="flex items-center gap-2">
        <span className="text-gray-800 mr-2">{item.formatted_quantity}</span>
        {onEdit && (
          <button
            className="px-3 py-1 bg-indigo-600 text-white rounded hover:bg-indigo-700"
            onClick={() => onEdit(item)}
          >
            編集
          </button>
        )}
        {onDelete && (
          <button
            className="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700"
            onClick={() => onDelete(item)}
          >
            削除
          </button>
        )}
      </div>
    </div>
  )
}

export default IngredientCard

