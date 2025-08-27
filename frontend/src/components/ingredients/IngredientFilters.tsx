import React from 'react'
import { CATEGORY_LABELS } from '../../constants/categories'

type Props = {
  name: string
  status: '' | 'available' | 'used' | 'expired'
  category: string
  sortBy: 'expiry_date' | 'quantity' | 'recent'
  onChange: (next: { name?: string; status?: Props['status']; category?: string; sortBy?: Props['sortBy'] }) => void
}

const IngredientFilters: React.FC<Props> = ({ name, status, category, sortBy, onChange }) => {
  const handle = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    if (name === 'name') onChange({ name: value })
  }

  return (
    <div className="flex flex-col md:flex-row gap-4 mb-6">
      <input
        name="name"
        type="text"
        placeholder="食材名で検索"
        className="px-3 py-2 border rounded w-full md:w-64"
        value={name}
        onChange={handle}
      />
      <select
        className="px-3 py-2 border rounded"
        value={status}
        onChange={(e) => onChange({ status: e.target.value as Props['status'] })}
      >
        <option value="">すべてのステータス</option>
        <option value="available">利用可能</option>
        <option value="used">使用済み</option>
        <option value="expired">期限切れ</option>
      </select>
      <select
        className="px-3 py-2 border rounded"
        value={category}
        onChange={(e) => onChange({ category: e.target.value })}
      >
        <option value="">すべてのカテゴリ</option>
        {Object.entries(CATEGORY_LABELS).map(([key, label]) => (
          <option key={key} value={key}>{label}</option>
        ))}
      </select>
      <select
        className="px-3 py-2 border rounded"
        value={sortBy}
        onChange={(e) => onChange({ sortBy: e.target.value as Props['sortBy'] })}
      >
        <option value="recent">最新</option>
        <option value="expiry_date">賞味期限が近い順</option>
        <option value="quantity">数量が多い順</option>
      </select>
    </div>
  )
}

export default IngredientFilters

