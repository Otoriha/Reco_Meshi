import React from 'react'
import { useFilters, type FilterPeriod } from '../../hooks/useFilters'

interface RecipeHistoryFiltersProps {
  filters: ReturnType<typeof useFilters>['filters']
  setPeriod: (period: FilterPeriod) => void
  setFavoritedOnly: (favoritedOnly: boolean | null) => void
  setSearchQuery: (query: string) => void
  hasActiveFilters: boolean
  clearFilters: () => void
}

const RecipeHistoryFilters: React.FC<RecipeHistoryFiltersProps> = ({
  filters,
  setPeriod,
  setFavoritedOnly,
  setSearchQuery,
  hasActiveFilters,
  clearFilters
}) => {
  const periodOptions = [
    { value: 'all' as const, label: 'すべて' },
    { value: 'this-week' as const, label: '今週' },
    { value: 'this-month' as const, label: '今月' }
  ]

  const ratingOptions = [
    { value: null, label: 'すべて表示' },
    { value: true, label: 'お気に入り' },
    { value: false, label: '未登録' }
  ]

  return (
    <div className="bg-white rounded-lg shadow-md p-6 mb-6">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-lg font-semibold text-gray-800">フィルタ</h3>
        {hasActiveFilters && (
          <button
            onClick={clearFilters}
            className="text-sm text-blue-600 hover:text-blue-800 font-medium"
          >
            クリア
          </button>
        )}
      </div>

      <div className="space-y-6">
        {/* 検索 */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            検索
          </label>
          <input
            type="text"
            value={filters.searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="レシピ名で検索..."
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        {/* 期間フィルタ */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            期間
          </label>
          <div className="flex gap-3 flex-wrap">
            {periodOptions.map((option) => (
              <button
                key={option.value}
                onClick={() => setPeriod(option.value)}
                className={`px-4 py-2 rounded-full border transition-colors ${
                  filters.period === option.value
                    ? 'bg-blue-500 text-white border-blue-500'
                    : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>

        {/* お気に入りフィルタ */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            お気に入り
          </label>
          <div className="flex gap-3 flex-wrap">
            {ratingOptions.map((option, index) => (
              <button
                key={index}
                onClick={() => setFavoritedOnly(option.value)}
                className={`px-4 py-2 rounded-full border transition-colors ${
                  filters.favoritedOnly === option.value
                    ? 'bg-blue-500 text-white border-blue-500'
                    : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default RecipeHistoryFilters