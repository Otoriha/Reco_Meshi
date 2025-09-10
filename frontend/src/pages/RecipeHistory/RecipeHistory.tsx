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
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">レシピ履歴</h1>
        
        {/* フィルタ */}
        <RecipeHistoryFilters
          filters={filters}
          setPeriod={setPeriod}
          setRatedOnly={setRatedOnly}
          setSearchQuery={setSearchQuery}
          hasActiveFilters={hasActiveFilters}
          clearFilters={clearFilters}
        />

        {filteredHistories.length === 0 && !loading ? (
          <div className="bg-white rounded-lg shadow-md p-12 text-center">
            <div className="text-6xl mb-6">🍽️</div>
            <h3 className="text-xl font-semibold text-gray-800 mb-4">
              {hasActiveFilters ? 'フィルタ条件に一致する履歴がありません' : '調理履歴がありません'}
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
                className="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
              >
                フィルタをクリア
              </button>
            ) : (
              <Link
                to="/recipes"
                className="inline-block bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
              >
                レシピを見る
              </Link>
            )}
          </div>
        ) : (
          <>
            <div className="space-y-6">
              {filteredHistories.map((history) => (
                <RecipeHistoryItem
                  key={history.id}
                  history={history}
                  onClick={() => handleItemClick(history)}
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