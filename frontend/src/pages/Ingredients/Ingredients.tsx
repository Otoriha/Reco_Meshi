import React, { useMemo, useState } from 'react'
import { useUserIngredients } from '../../hooks/useUserIngredients'
import IngredientList from '../../components/ingredients/IngredientList'
import IngredientFilters from '../../components/ingredients/IngredientFilters'
import AddIngredientModal from '../../components/ingredients/AddIngredientModal'
import EditIngredientModal from '../../components/ingredients/EditIngredientModal'
import type { UserIngredient } from '../../types/ingredient'

const Ingredients: React.FC = () => {
  const {
    groupBy,
    setGroupBy,
    loading,
    error,
    filters,
    setFilters,
    items,
    groups,
    add,
    update,
    remove,
  } = useUserIngredients('category')

  const [isAddOpen, setIsAddOpen] = useState(false)
  const [editing, setEditing] = useState<UserIngredient | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)

  const totalCount = useMemo(() => items.length, [items])

  const handleAdd = async (data: { ingredient_id: number; quantity: number; expiry_date?: string | null }) => {
    setPageError(null)
    try {
      await add(data)
    } catch (e: any) {
      const msg = e?.response?.data?.status?.message || e?.message || '追加に失敗しました。'
      setPageError(msg)
      throw e
    }
  }

  const handleEdit = (item: UserIngredient) => setEditing(item)
  const handleDelete = async (item: UserIngredient) => {
    if (!confirm('この食材を削除しますか？')) return
    try {
      await remove(item.id)
    } catch (e) {
      setPageError('削除に失敗しました。')
    }
  }

  const handleUpdate = async (data: { quantity?: number; expiry_date?: string | null; status?: 'available' | 'used' | 'expired' }) => {
    if (!editing) return
    setPageError(null)
    try {
      await update(editing.id, data)
      setEditing(null)
    } catch (e: any) {
      const msg = e?.response?.data?.status?.message || e?.message || '更新に失敗しました。'
      setPageError(msg)
      throw e
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-3xl font-bold text-gray-900">食材リスト</h1>
          <div className="flex items-center gap-2">
            <button
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              onClick={() => setIsAddOpen(true)}
            >
              追加
            </button>
            <button
              className="px-4 py-2 bg-gray-200 text-gray-800 rounded hover:bg-gray-300"
              onClick={() => setGroupBy(groupBy === 'category' ? 'none' : 'category')}
            >
              {groupBy === 'category' ? 'グループ解除' : 'カテゴリでグループ'}
            </button>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          {loading && <p className="text-gray-600">読み込み中...</p>}

          {!loading && (error || pageError) && (
            <div className="mb-4 p-3 rounded bg-red-50 text-red-700 border border-red-200">
              {pageError || error}
            </div>
          )}

          {!loading && (
            <IngredientFilters
              name={filters.name || ''}
              status={(filters.status as any) || ''}
              category={(filters.category as any) || ''}
              sortBy={(filters.sort_by as any) || 'recent'}
              onChange={(next) =>
                setFilters({
                  ...filters,
                  ...(next.name !== undefined ? { name: next.name } : {}),
                  ...(next.status !== undefined ? { status: next.status } : {}),
                  ...(next.category !== undefined ? { category: next.category } : {}),
                  ...(next.sortBy !== undefined ? { sort_by: next.sortBy } : {}),
                })
              }
            />
          )}

          {!loading && totalCount === 0 && (
            <p className="text-gray-600">食材がありません。</p>
          )}

          {!loading && totalCount > 0 && (
            <IngredientList
              groupBy={groupBy}
              items={items}
              groups={groups}
              onEdit={handleEdit}
              onDelete={handleDelete}
            />
          )}
        </div>
      </div>

      <AddIngredientModal
        isOpen={isAddOpen}
        onClose={() => setIsAddOpen(false)}
        onSubmit={handleAdd}
      />

      <EditIngredientModal
        isOpen={!!editing}
        item={editing}
        onClose={() => setEditing(null)}
        onSubmit={handleUpdate}
      />
    </div>
  )
}

export default Ingredients
