import React from 'react'
import type { UserIngredient } from '../../types/ingredient'
import { FaEdit, FaTrash } from 'react-icons/fa'

type Props = {
  item: UserIngredient
  onEdit?: (item: UserIngredient) => void
  onDelete?: (item: UserIngredient) => void
}

const IngredientCardNew: React.FC<Props> = ({ item, onEdit, onDelete }) => {
  const name = item.ingredient?.name || item.display_name
  const emoji = item.ingredient?.emoji || '🍽️'

  return (
    <div className="bg-white border rounded-lg p-4 hover:shadow-md transition-shadow relative">
      {/* 編集・削除ボタン */}
      <div className="absolute top-2 right-2 flex gap-1">
        {onEdit && (
          <button
            onClick={() => onEdit(item)}
            className="p-1 text-gray-400 hover:text-orange-500 hover:bg-orange-50 rounded"
            title="編集"
          >
            <FaEdit className="w-4 h-4" />
          </button>
        )}
        {onDelete && (
          <button
            onClick={() => onDelete(item)}
            className="p-1 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded"
            title="削除"
          >
            <FaTrash className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* 食材情報 */}
      <div className="text-center">
        <div className="text-4xl mb-2">{emoji}</div>
        <h3 className="font-medium text-gray-900 mb-1">{name}</h3>
        <p className="text-gray-600 text-sm">{item.formatted_quantity}</p>
      </div>
    </div>
  )
}

export default IngredientCardNew