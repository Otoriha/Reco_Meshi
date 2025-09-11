import React from 'react'

const RecipeHistorySkeleton: React.FC = () => {
  return (
    <div className="bg-white rounded-lg shadow-md p-6 animate-pulse">
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <div className="h-6 bg-gray-300 rounded w-3/4 mb-3"></div>
          <div className="h-4 bg-gray-200 rounded w-1/2"></div>
        </div>
        <div className="ml-6 flex flex-col items-end space-y-2">
          <div className="h-5 bg-gray-200 rounded w-20"></div>
          <div className="h-4 bg-gray-200 rounded w-16"></div>
        </div>
      </div>
      
      <div className="mt-4 p-4 bg-gray-50 rounded-lg">
        <div className="h-4 bg-gray-200 rounded w-full mb-2"></div>
        <div className="h-4 bg-gray-200 rounded w-2/3"></div>
      </div>
      
      <div className="mt-4 flex items-center space-x-6">
        <div className="h-3 bg-gray-200 rounded w-20"></div>
        <div className="h-3 bg-gray-200 rounded w-24"></div>
      </div>
    </div>
  )
}

interface RecipeHistorySkeletonListProps {
  count?: number
}

export const RecipeHistorySkeletonList: React.FC<RecipeHistorySkeletonListProps> = ({ 
  count = 5 
}) => {
  return (
    <div className="space-y-6">
      {Array.from({ length: count }, (_, index) => (
        <RecipeHistorySkeleton key={index} />
      ))}
    </div>
  )
}

export default RecipeHistorySkeleton