import React, { useState, useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { useRecipeHistory } from '../../hooks/useRecipeHistory'
import { useFilters } from '../../hooks/useFilters'
import RecipeHistoryFilters from './RecipeHistoryFilters'
import RecipeHistoryItem from './RecipeHistoryItem'
import RecipeHistoryModal from './RecipeHistoryModal'
import { RecipeHistorySkeletonList } from './RecipeHistorySkeleton'
import Pagination from '../../components/Pagination'
import type { RecipeHistory as RecipeHistoryType, UpdateRecipeHistoryParams } from '../../types/recipe'
import { FaSearch, FaStar } from 'react-icons/fa'

const RecipeHistory: React.FC = () => {
  const {
    histories,
    loading,
    error,
    initialized,
    fetchHistories,
    updateHistory,
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

  const [selectedHistory, setSelectedHistory] = useState<RecipeHistoryType | null>(null)
  const [isModalOpen, setIsModalOpen] = useState(false)

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
    setSelectedHistory(history)
    setIsModalOpen(true)
  }

  const handleModalClose = () => {
    setIsModalOpen(false)
    setSelectedHistory(null)
  }

  const handleUpdate = async (id: number, params: UpdateRecipeHistoryParams) => {
    await updateHistory(id, params)
    handleModalClose()
  }

  const handleDelete = async (id: number) => {
    await deleteHistory(id)
    
    // 削除後に現在のページが空になった場合の処理
    setTimeout(() => {
      const filteredAfterDelete = filterLocalData(histories.filter(h => h.id !== id))
      if (filteredAfterDelete.length === 0 && currentPage > 1) {
        // 現在のページが空で、かつ1ページ目以外の場合は前のページに移動
        handlePageChange(currentPage - 1)
      }
    }, 100) // 少し遅延させてstate更新を待つ
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

        {/* 検索バーとフィルターボタン */}
        <div className="flex items-center gap-4 mb-6">
          <div className="flex-1 relative">
            <FaSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
            <input
              type="text"
              placeholder="レシピを検索..."
              value={filters.searchQuery || ''}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
            />
          </div>
          <button
            onClick={() => setRatedOnly(!filters.ratedOnly)}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filters.ratedOnly
                ? 'bg-green-600 text-white'
                : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
            }`}
          >
            すべて
          </button>
          <button
            onClick={() => setRatedOnly(true)}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filters.ratedOnly
                ? 'bg-green-600 text-white'
                : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
            }`}
          >
            お気に入り
          </button>
          <button className="px-4 py-2 bg-white text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">
            簡単
          </button>
          <button className="px-4 py-2 bg-white text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">
            買い物なし
          </button>
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
                />
              ))}
            </div>

            {/* ページネーション */}
            <div className="flex justify-center mt-8">
              <nav className="flex items-center space-x-2">
                <button
                  onClick={() => currentPage > 1 && handlePageChange(currentPage - 1)}
                  disabled={currentPage === 1 || loading}
                  className="px-3 py-1 text-gray-500 hover:text-gray-700 disabled:opacity-50"
                >
                  ‹
                </button>
                {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                  const page = i + 1
                  return (
                    <button
                      key={page}
                      onClick={() => handlePageChange(page)}
                      disabled={loading}
                      className={`px-3 py-1 rounded ${
                        currentPage === page
                          ? 'bg-green-600 text-white'
                          : 'text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      {page}
                    </button>
                  )
                })}
                <button
                  onClick={() => currentPage < totalPages && handlePageChange(currentPage + 1)}
                  disabled={currentPage === totalPages || loading}
                  className="px-3 py-1 text-gray-500 hover:text-gray-700 disabled:opacity-50"
                >
                  ›
                </button>
              </nav>
            </div>
          </>
        )}

        {/* 詳細モーダル */}
        <RecipeHistoryModal
          history={selectedHistory}
          isOpen={isModalOpen}
          onClose={handleModalClose}
          onUpdate={handleUpdate}
          onDelete={handleDelete}
        />
      </div>
    </div>
  )
}

export default RecipeHistory