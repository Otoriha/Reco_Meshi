import React, { useEffect, useMemo } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useRecipeHistory } from '../../hooks/useRecipeHistory'
import { useFilters, type FilterPeriod } from '../../hooks/useFilters'
import RecipeHistoryItem from './RecipeHistoryItem'
import { RecipeHistorySkeletonList } from './RecipeHistorySkeleton'
import Pagination from '../../components/Pagination'
import type { RecipeHistory as RecipeHistoryType } from '../../types/recipe'
import { FaSearch } from 'react-icons/fa'

const PERIOD_OPTIONS: Array<{ value: FilterPeriod; label: string }> = [
  { value: 'all', label: 'すべて' },
  { value: 'this-week', label: '今週' },
  { value: 'this-month', label: '今月' },
]

const RATING_OPTIONS: Array<{ value: boolean | null; label: string }> = [
  { value: null, label: 'すべて' },
  { value: true, label: 'お気に入り' },
  { value: false, label: '未評価' },
]

const RecipeHistory: React.FC = () => {
  const navigate = useNavigate()
  const {
    histories,
    loading,
    error,
    initialized,
    fetchHistories,
    deleteHistory,
    currentPage,
    totalPages
  } = useRecipeHistory()

  const {
    filters,
    setPeriod,
    setRatedOnly,
    setSearchQuery,
    getApiParams,
    filterLocalData,
    hasActiveFilters,
    clearFilters
  } = useFilters()

  // フィルタ変更時にデータを再取得
  useEffect(() => {
    const apiParams = getApiParams()
    fetchHistories({ ...apiParams, page: 1 })
  }, [filters.period, filters.ratedOnly, getApiParams, fetchHistories])

  // 初回データ取得
  useEffect(() => {
    if (!initialized) {
      fetchHistories()
    }
  }, [initialized, fetchHistories])

  // ローカルフィルタを適用したデータ
  const filteredHistories = useMemo(() => {
    return filterLocalData(histories)
  }, [histories, filterLocalData])

  const handleItemClick = (history: RecipeHistoryType) => {
    if (history.recipe_id) {
      navigate(`/recipes/${history.recipe_id}`)
    }
  }

  const handleItemDelete = async (id: number) => {
    await deleteHistory(id)
  }


  const handlePageChange = async (page: number) => {
    const apiParams = getApiParams()
    await fetchHistories({ ...apiParams, page })
  }

  if (loading && histories.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-8">レシピ履歴</h1>
          <div className="text-center py-8">
            <p className="text-gray-600">読み込み中...</p>
          </div>
          <RecipeHistorySkeletonList count={5} />
        </div>
      </div>
    )
  }

  if (error && histories.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-8">レシピ履歴</h1>
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <p className="text-red-700 text-center">{error}</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">レシピ履歴</h1>

        {/* 検索とフィルタ */}
        <div className="bg-white rounded-lg shadow-sm p-4 mb-6 space-y-4">
          <div className="flex items-center gap-4">
            <div className="flex-1 relative">
              <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-4 h-4" />
              <input
                type="text"
                placeholder="レシピを検索..."
                value={filters.searchQuery || ''}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              />
            </div>
            {hasActiveFilters && (
              <button
                type="button"
                onClick={clearFilters}
                className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                フィルタをリセット
              </button>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {PERIOD_OPTIONS.map((option) => (
              <button
                key={option.value}
                type="button"
                onClick={() => setPeriod(option.value)}
                className={`px-3 py-1.5 rounded-full text-sm border transition-colors ${
                  filters.period === option.value
                    ? 'bg-green-600 text-white border-green-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {RATING_OPTIONS.map((option) => (
              <button
                key={option.label}
                type="button"
                onClick={() => setRatedOnly(option.value)}
                className={`px-3 py-1.5 rounded-full text-sm border transition-colors ${
                  filters.ratedOnly === option.value
                    ? 'bg-green-600 text-white border-green-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>

        {filteredHistories.length === 0 && !loading ? (
          <div className="bg-white rounded-lg shadow-sm p-12 text-center">
            <div className="text-6xl mb-6">🍽️</div>
            <h3 className="text-xl font-semibold text-gray-800 mb-4">
              {hasActiveFilters ? 'フィルタ条件に一致する履歴がありません' : 'レシピ履歴がありません'}
            </h3>
            <p className="text-gray-600 mb-6">
              {hasActiveFilters
                ? 'フィルタ条件を変更してみてください'
                : 'レシピを作って「作った！」ボタンを押すと履歴が記録されます'
              }
            </p>
            {hasActiveFilters ? (
              <button
                onClick={clearFilters}
                className="bg-green-600 hover:bg-green-700 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
              >
                クリア
              </button>
            ) : (
              <Link
                to="/recipes"
                className="inline-block bg-green-600 hover:bg-green-700 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
              >
                レシピを見る
              </Link>
            )}
          </div>
        ) : (
          <>
            <div className="space-y-4">
              {filteredHistories.map((history) => (
                <RecipeHistoryItem
                  key={history.id}
                  history={history}
                  onClick={() => handleItemClick(history)}
                  onDelete={() => handleItemDelete(history.id)}
                />
              ))}
            </div>

            {/* ページネーション */}
            <Pagination
              currentPage={currentPage}
              totalPages={totalPages}
              onPageChange={handlePageChange}
              loading={loading}
            />
          </>
        )}

      </div>
    </div>
  )
}

export default RecipeHistory
