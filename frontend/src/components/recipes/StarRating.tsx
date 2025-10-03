import React from 'react'
import { FaStar, FaRegStar } from 'react-icons/fa'

interface StarRatingProps {
  rating: number | null
  onRate?: (rating: number | null) => void
  readonly?: boolean
  size?: 'sm' | 'md' | 'lg'
}

const StarRating: React.FC<StarRatingProps> = ({
  rating,
  onRate,
  readonly = false,
  size = 'md'
}) => {
  const sizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-5 h-5',
    lg: 'w-6 h-6'
  }

  const handleClick = (value: number) => {
    if (readonly || !onRate) return
    // 同じ星をクリックした場合は評価を削除
    if (rating === value) {
      onRate(null)
    } else {
      onRate(value)
    }
  }

  return (
    <div className="flex items-center space-x-1">
      {[1, 2, 3, 4, 5].map((value) => {
        const isActive = rating !== null && value <= rating
        const StarIcon = isActive ? FaStar : FaRegStar

        return (
          <button
            key={value}
            type="button"
            onClick={() => handleClick(value)}
            disabled={readonly}
            className={`
              ${sizeClasses[size]}
              ${readonly ? 'cursor-default' : 'cursor-pointer hover:scale-110 transition-transform'}
              ${isActive ? 'text-yellow-400' : 'text-gray-300'}
              focus:outline-none
            `}
            aria-label={`${value}つ星`}
          >
            <StarIcon className="w-full h-full" />
          </button>
        )
      })}
    </div>
  )
}

export default StarRating
