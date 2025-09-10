import React, { useState, useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { useRecipeHistory } from '../../hooks/useRecipeHistory'
import { useFilters } from '../../hooks/useFilters'
import { useInfiniteScroll } from '../../hooks/useInfiniteScroll'
import RecipeHistoryFilters from './RecipeHistoryFilters'
import RecipeHistoryItem from './RecipeHistoryItem'
import RecipeHistoryModal from './RecipeHistoryModal'
import { RecipeHistorySkeletonList } from './RecipeHistorySkeleton'
import type { RecipeHistory as RecipeHistoryType, UpdateRecipeHistoryParams } from '../../types/recipe'

const RecipeHistory: React.FC = () => {
  const {
    histories,
    loading,
    loadingMore,
    error,
    hasNextPage,
    fetchHistories,
    loadMore,
    updateHistory,
    deleteHistory
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
    fetchHistories(apiParams, true)
  }, [filters.period, filters.ratedOnly, getApiParams, fetchHistories])

  // 無限スクロール用のセンチネル
  const { ref: infiniteScrollRef } = useInfiniteScroll({
    hasNextPage,
    isLoading: loadingMore,
    onLoadMore: loadMore
  })

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

  if (loading && histories.length === 0) {
    return (
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">レシピ履歴</h1>
        <RecipeHistorySkeletonList count={5} />
      </div>
    )
  }

  if (error && histories.length === 0) {
    return (
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">レシピ履歴</h1>
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-700">{error}</p>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">レシピ履歴</h1>
      
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
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-8 text-center">
          <div className="text-6xl mb-4">🍽️</div>
          <p className="text-gray-600 mb-2">
            {hasActiveFilters ? 'フィルタ条件に一致する履歴がありません' : '調理履歴がありません'}
          </p>
          <p className="text-sm text-gray-500 mb-4">
            {hasActiveFilters 
              ? 'フィルタ条件を変更してみてください'
              : 'レシピを作って「作った！」ボタンを押すと履歴が記録されます'
            }
          </p>
          {hasActiveFilters ? (
            <button
              onClick={clearFilters}
              className="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg transition-colors"
            >
              フィルタをクリア
            </button>
          ) : (
            <Link
              to="/recipes"
              className="inline-block bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg transition-colors"
            >
              レシピを見る
            </Link>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          {filteredHistories.map((history) => (
            <RecipeHistoryItem
              key={history.id}
              history={history}
              onClick={() => handleItemClick(history)}
            />
          ))}
          
          {/* 無限スクロール用のセンチネル */}
          {hasNextPage && (
            <div ref={infiniteScrollRef} className="py-4">
              {loadingMore && <RecipeHistorySkeletonList count={3} />}
            </div>
          )}
        </div>
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
  )
}

export default RecipeHistory