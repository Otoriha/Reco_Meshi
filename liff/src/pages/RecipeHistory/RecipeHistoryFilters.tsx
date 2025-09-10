import React from 'react'
import { useFilters, type FilterPeriod } from '../../hooks/useFilters'

interface RecipeHistoryFiltersProps {
  filters: ReturnType<typeof useFilters>['filters']
  setPeriod: (period: FilterPeriod) => void
  setRatedOnly: (ratedOnly: boolean | null) => void
  setSearchQuery: (query: string) => void
  hasActiveFilters: boolean
  clearFilters: () => void
}

const RecipeHistoryFilters: React.FC<RecipeHistoryFiltersProps> = ({
  filters,
  setPeriod,
  setRatedOnly,
  setSearchQuery,
  hasActiveFilters,
  clearFilters
}) => {
  const periodOptions = [
    { value: 'all' as const, label: '全期間' },
    { value: 'this-week' as const, label: '今週' },
    { value: 'this-month' as const, label: '今月' }
  ]

  const ratingOptions = [
    { value: null, label: '全て' },
    { value: true, label: '評価済み' },
    { value: false, label: '未評価' }
  ]

  return (
    <div className="bg-white rounded-lg shadow-md p-4 mb-4">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-semibold text-gray-700">フィルタ</h3>
        {hasActiveFilters && (
          <button
            onClick={clearFilters}
            className="text-xs text-blue-500 hover:text-blue-700"
          >
            クリア
          </button>
        )}
      </div>

      <div className="space-y-4">
        {/* 検索 */}
        <div>
          <label className="block text-xs font-medium text-gray-700 mb-1">
            検索
          </label>
          <input
            type="text"
            value={filters.searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="レシピ名やメモで検索"
            className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        {/* 期間フィルタ */}
        <div>
          <label className="block text-xs font-medium text-gray-700 mb-2">
            期間
          </label>
          <div className="flex gap-2">
            {periodOptions.map((option) => (
              <button
                key={option.value}
                onClick={() => setPeriod(option.value)}
                className={`px-3 py-1 text-xs rounded-full border transition-colors ${
                  filters.period === option.value
                    ? 'bg-blue-500 text-white border-blue-500'
                    : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>

        {/* 評価フィルタ */}
        <div>
          <label className="block text-xs font-medium text-gray-700 mb-2">
            評価
          </label>
          <div className="flex gap-2">
            {ratingOptions.map((option, index) => (
              <button
                key={index}
                onClick={() => setRatedOnly(option.value)}
                className={`px-3 py-1 text-xs rounded-full border transition-colors ${
                  filters.ratedOnly === option.value
                    ? 'bg-blue-500 text-white border-blue-500'
                    : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'
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