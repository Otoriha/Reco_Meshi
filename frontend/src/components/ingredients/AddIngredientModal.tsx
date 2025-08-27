import React, { useMemo, useState } from 'react'
import Modal from '../ui/Modal'
import { useIngredients } from '../../hooks/useIngredients'

type Props = {
  isOpen: boolean
  onClose: () => void
  onSubmit: (data: { ingredient_id: number; quantity: number; expiry_date?: string | null }) => Promise<void>
}

const AddIngredientModal: React.FC<Props> = ({ isOpen, onClose, onSubmit }) => {
  const { items, search, setSearch } = useIngredients({ perPage: 20 })
  const [selectedId, setSelectedId] = useState<number | ''>('')
  const [quantity, setQuantity] = useState<number | ''>('')
  const [expiry, setExpiry] = useState<string>('')
  const [error, setError] = useState<string | null>(null)
  
  const canSubmit = useMemo(() => {
    const q = Number(quantity)
    return !!selectedId && !Number.isNaN(q) && q > 0
  }, [selectedId, quantity])

  const handleSubmit = async () => {
    setError(null)
    const q = Number(quantity)
    if (!selectedId) return
    if (Number.isNaN(q) || q <= 0) {
      setError('数量は0より大きい数値で入力してください。')
      return
    }
    // available時に過去日を拒否（MVP簡易チェック）
    if (expiry) {
      const today = new Date()
      today.setHours(0,0,0,0)
      const d = new Date(expiry)
      if (d < today) {
        setError('賞味期限に過去の日付は指定できません。')
        return
      }
    }
    try {
      await onSubmit({ ingredient_id: Number(selectedId), quantity: q, expiry_date: expiry || null })
      setSelectedId('')
      setQuantity('')
      setExpiry('')
      onClose()
    } catch (e: any) {
      const msg = e?.response?.data?.status?.message || e?.message || '追加に失敗しました。'
      setError(msg)
    }
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="食材を追加">
      <div className="space-y-3">
        {error && <div className="text-sm text-red-600 bg-red-50 border border-red-200 p-2 rounded">{error}</div>}
        <div>
          <label className="block text-sm text-gray-700 mb-1">食材を検索</label>
          <input
            type="text"
            className="w-full px-3 py-2 border rounded"
            placeholder="例: にんじん"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-1">食材</label>
          <select className="w-full px-3 py-2 border rounded" value={selectedId} onChange={(e) => setSelectedId(e.target.value ? Number(e.target.value) : '')}>
            <option value="">選択してください</option>
            {items.map((i) => (
              <option key={i.id} value={i.id}>{i.emoji} {i.name}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-1">数量</label>
          <input
            type="number"
            step="any"
            className="w-full px-3 py-2 border rounded"
            value={quantity}
            onChange={(e) => setQuantity(e.target.value === '' ? '' : Number(e.target.value))}
          />
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-1">賞味期限（任意）</label>
          <input
            type="date"
            className="w-full px-3 py-2 border rounded"
            value={expiry}
            onChange={(e) => setExpiry(e.target.value)}
          />
        </div>
        <div className="flex justify-end gap-2 pt-2">
          <button className="px-4 py-2 bg-gray-200 text-gray-800 rounded" onClick={onClose}>キャンセル</button>
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
            disabled={!canSubmit}
            onClick={handleSubmit}
          >
            追加
          </button>
        </div>
      </div>
    </Modal>
  )
}

export default AddIngredientModal

