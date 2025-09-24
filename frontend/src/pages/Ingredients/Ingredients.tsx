import React, { useMemo, useState } from 'react'
import { useUserIngredients } from '../../hooks/useUserIngredients'
import IngredientCardNew from '../../components/ingredients/IngredientCardNew'
import AddIngredientModal from '../../components/ingredients/AddIngredientModal'
import EditIngredientModal from '../../components/ingredients/EditIngredientModal'
import type { UserIngredient } from '../../types/ingredient'
import { FaSearch, FaPlus } from 'react-icons/fa'
import { CATEGORY_LABELS } from '../../constants/categories'

const CATEGORY_EMOJI: Record<string, string> = {
  vegetables: '🥬',
  meat: '🥩',
  fish: '🐟',
  dairy: '🥛',
  seasonings: '🧂',
  others: '🍽️',
}

const Ingredients: React.FC = () => {
  const {
    loading,
    error,
    items,
    add,
    update,
    remove,
  } = useUserIngredients('category')

  const [isAddOpen, setIsAddOpen] = useState(false)
  const [editing, setEditing] = useState<UserIngredient | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('すべて')

  const totalCount = useMemo(() => items.length, [items])

  // カテゴリー別のカウントを計算
  const categoryCounts = useMemo(() => {
    const counts: Record<string, number> = {}
    items.forEach(item => {
      const category = item.ingredient?.category || 'others'
      counts[category] = (counts[category] || 0) + 1
    })
    return counts
  }, [items])

  // フィルタリングされた食材
  const filteredItems = useMemo(() => {
    const normalizedTerm = searchTerm.trim().toLowerCase()

    return items.filter((item) => {
      const ingredientName = item.ingredient?.name?.toLowerCase() ?? ''
      const displayName = item.display_name?.toLowerCase() ?? ''

      const matchesSearch = !normalizedTerm ||
        ingredientName.includes(normalizedTerm) ||
        displayName.includes(normalizedTerm)

      const matchesCategory = selectedCategory === 'すべて' || item.ingredient?.category === selectedCategory

      return matchesSearch && matchesCategory
    })
  }, [items, searchTerm, selectedCategory])


  const handleAdd = async (data: { ingredient_id: number; quantity: number; expiry_date?: string | null }) => {
    setPageError(null)
    try {
      await add(data)
    } catch (e: unknown) {
      const error = e as { response?: { data?: { status?: { message?: string } } }; message?: string };
      const msg = error?.response?.data?.status?.message || error?.message || '追加に失敗しました。';
      setPageError(msg);
      throw e;
    }
  }

  const handleEdit = (item: UserIngredient) => setEditing(item)
  const handleDelete = async (item: UserIngredient) => {
    if (!confirm('この食材を削除しますか？')) return
    try {
      await remove(item.id)
    } catch {
      setPageError('削除に失敗しました。')
    }
  }

  const handleUpdate = async (data: { quantity?: number; expiry_date?: string | null; status?: 'available' | 'used' | 'expired' }) => {
    if (!editing) return
    setPageError(null)
    try {
      await update(editing.id, data)
      setEditing(null)
    } catch (e: unknown) {
      const error = e as { response?: { data?: { status?: { message?: string } } }; message?: string };
      const msg = error?.response?.data?.status?.message || error?.message || '更新に失敗しました。';
      setPageError(msg);
      throw e;
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex">
          {/* 左サイドバー */}
          <div className="w-64 bg-white rounded-lg shadow-sm p-6 mr-6 h-fit">
            {/* 在庫状況 */}
            <div className="mb-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">在庫状況</h3>
              <div className="text-center">
                <div className="text-4xl font-bold text-green-600 mb-2">{totalCount}</div>
                <div className="text-gray-600 text-sm">登録食材数</div>
              </div>
            </div>

            {/* カテゴリー */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">カテゴリー</h3>
              <div className="space-y-2">
                <button
                  type="button"
                  onClick={() => setSelectedCategory('すべて')}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-left ${
                    selectedCategory === 'すべて'
                      ? 'bg-green-100 text-green-800 font-medium'
                      : 'hover:bg-gray-50'
                  }`}
                >
                  <span className="flex items-center">
                    <span className="mr-2">🍽️</span>
                    すべて
                  </span>
                  <span className="bg-green-500 text-white text-xs px-2 py-1 rounded-full">
                    {totalCount}
                  </span>
                </button>

                {Object.entries(CATEGORY_LABELS).map(([key, label]) => {
                  const count = categoryCounts[key] || 0
                  const emoji = CATEGORY_EMOJI[key] ?? '🍽️'

                  return (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setSelectedCategory(key)}
                      className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-left ${
                        selectedCategory === key
                          ? 'bg-green-100 text-green-800 font-medium'
                          : 'hover:bg-gray-50'
                      }`}
                    >
                      <span className="flex items-center">
                        <span className="mr-2">{emoji}</span>
                        {label}
                      </span>
                      <span className="bg-gray-300 text-gray-700 text-xs px-2 py-1 rounded-full">
                        {count}
                      </span>
                    </button>
                  )
                })}
              </div>
            </div>
          </div>

          {/* メインコンテンツ */}
          <div className="flex-1">
            {/* ヘッダー */}
            <div className="flex items-center justify-between mb-6">
              <h1 className="text-2xl font-bold text-gray-900">食材リスト</h1>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setIsAddOpen(true)}
                  className="flex items-center gap-2 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 font-medium"
                >
                  <FaPlus className="w-4 h-4" />
                  手動で食材を追加
                </button>
              </div>
            </div>

            {/* 検索バー */}
            <div className="flex items-center gap-4 mb-6">
              <div className="flex-1 relative">
                <FaSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                <input
                  type="text"
                  placeholder="食材を検索..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                />
              </div>
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              >
                <option value="すべて">すべて表示</option>
                {Object.entries(CATEGORY_LABELS).map(([key, label]) => (
                  <option key={key} value={key}>{label}</option>
                ))}
              </select>
            </div>

            {/* エラー表示 */}
            {!loading && (error || pageError) && (
              <div className="mb-4 p-3 rounded bg-red-50 text-red-700 border border-red-200">
                {pageError || error}
              </div>
            )}

            {/* 食材リスト */}
            <div className="bg-white rounded-lg shadow-sm">
              {loading ? (
                <div className="p-6">
                  <p className="text-gray-600">読み込み中...</p>
                </div>
              ) : filteredItems.length === 0 ? (
                <div className="p-6">
                  <p className="text-gray-600">
                    {searchTerm || selectedCategory !== 'すべて'
                      ? '条件に一致する食材がありません。'
                      : '食材がありません。'}
                  </p>
                </div>
              ) : (
                <div className="p-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {filteredItems.map((item) => (
                      <IngredientCardNew
                        key={item.id}
                        item={item}
                        onEdit={handleEdit}
                        onDelete={handleDelete}
                      />
                    ))}
                  </div>

                  <div className="mt-6 text-center text-sm text-gray-600">
                    {`該当件数: ${filteredItems.length}件`}
                  </div>
                </div>
              )}
            </div>
          </div>
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
