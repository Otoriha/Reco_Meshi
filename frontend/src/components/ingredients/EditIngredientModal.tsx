import React, { useMemo, useState } from 'react'
import Modal from '../ui/Modal'
import type { UserIngredient } from '../../types/ingredient'

type Props = {
  isOpen: boolean
  item: UserIngredient | null
  onClose: () => void
  onSubmit: (data: { quantity?: number; expiry_date?: string | null; status?: 'available' | 'used' | 'expired' }) => Promise<void>
}

const EditIngredientModal: React.FC<Props> = ({ isOpen, item, onClose, onSubmit }) => {
  const [quantity, setQuantity] = useState<number | ''>('')
  const [expiry, setExpiry] = useState<string>('')
  const [status, setStatus] = useState<'available' | 'used' | 'expired'>(item?.status || 'available')
  const [error, setError] = useState<string | null>(null)

  React.useEffect(() => {
    if (item) {
      setQuantity(item.quantity)
      setExpiry(item.expiry_date || '')
      setStatus(item.status)
    }
  }, [item])

  const canSubmit = useMemo(() => {
    const q = quantity === '' ? NaN : Number(quantity)
    return !Number.isNaN(q) && (q as number) > 0
  }, [quantity])

  const handleSubmit = async () => {
    setError(null)
    const q = Number(quantity)
    if (Number.isNaN(q) || q <= 0) {
      setError('数量は0より大きい数値で入力してください。')
      return
    }
    if (status === 'available' && expiry) {
      const today = new Date()
      today.setHours(0,0,0,0)
      const d = new Date(expiry)
      if (d < today) {
        setError('賞味期限に過去の日付は指定できません。')
        return
      }
    }
    try {
      await onSubmit({ quantity: q, expiry_date: expiry || null, status })
      onClose()
    } catch (e: any) {
      const msg = e?.response?.data?.status?.message || e?.message || '更新に失敗しました。'
      setError(msg)
    }
  }

  const name = item?.ingredient?.name || item?.display_name || ''

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`${name} を編集`}>
      <div className="space-y-3">
        {error && <div className="text-sm text-red-600 bg-red-50 border border-red-200 p-2 rounded">{error}</div>}
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
        <div>
          <label className="block text-sm text-gray-700 mb-1">ステータス</label>
          <select
            className="w-full px-3 py-2 border rounded"
            value={status}
            onChange={(e) => setStatus(e.target.value as any)}
          >
            <option value="available">利用可能</option>
            <option value="used">使用済み</option>
            <option value="expired">期限切れ</option>
          </select>
        </div>
        <div className="flex justify-end gap-2 pt-2">
          <button className="px-4 py-2 bg-gray-200 text-gray-800 rounded" onClick={onClose}>キャンセル</button>
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
            disabled={!canSubmit}
            onClick={handleSubmit}
          >
            保存
          </button>
        </div>
      </div>
    </Modal>
  )
}

export default EditIngredientModal

