import { useInView } from 'react-intersection-observer'
import { useCallback, useRef } from 'react'
import type { PaginationMeta } from '../api/recipes'

interface UseInfiniteScrollParams {
  hasNextPage: boolean
  isLoading: boolean
  onLoadMore: () => void
  threshold?: number
  rootMargin?: string
  throttleMs?: number
}

interface UseInfiniteScrollReturn {
  ref: (node?: Element | null) => void
  inView: boolean
}

export const useInfiniteScroll = ({
  hasNextPage,
  isLoading,
  onLoadMore,
  threshold = 0.1,
  rootMargin = '100px',
  throttleMs = 300
}: UseInfiniteScrollParams): UseInfiniteScrollReturn => {
  const lastCallTimeRef = useRef<number>(0)
  const timeoutRef = useRef<NodeJS.Timeout | null>(null)

  const throttledLoadMore = useCallback(() => {
    const now = Date.now()
    const timeSinceLastCall = now - lastCallTimeRef.current

    if (timeSinceLastCall >= throttleMs) {
      // 即座に実行
      lastCallTimeRef.current = now
      onLoadMore()
    } else {
      // 残り時間後に実行（既存のタイマーはキャンセル）
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current)
      }
      
      const remainingTime = throttleMs - timeSinceLastCall
      timeoutRef.current = setTimeout(() => {
        lastCallTimeRef.current = Date.now()
        onLoadMore()
      }, remainingTime)
    }
  }, [onLoadMore, throttleMs])

  const { ref, inView } = useInView({
    threshold,
    rootMargin,
    onChange: (inView: boolean) => {
      if (inView && hasNextPage && !isLoading) {
        throttledLoadMore()
      }
    }
  })

  return { ref, inView }
}

export const hasMorePages = (meta?: PaginationMeta): boolean => {
  if (!meta) return false
  return meta.current_page < meta.total_pages
}