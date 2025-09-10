import { useInView } from 'react-intersection-observer'
import type { PaginationMeta } from '../api/recipes'

interface UseInfiniteScrollParams {
  hasNextPage: boolean
  isLoading: boolean
  onLoadMore: () => void
  threshold?: number
  rootMargin?: string
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
  rootMargin = '100px'
}: UseInfiniteScrollParams): UseInfiniteScrollReturn => {
  const { ref, inView } = useInView({
    threshold,
    rootMargin,
    onChange: (inView: boolean) => {
      if (inView && hasNextPage && !isLoading) {
        onLoadMore()
      }
    }
  })

  return { ref, inView }
}

export const hasMorePages = (meta?: PaginationMeta): boolean => {
  if (!meta) return false
  return meta.current_page < meta.total_pages
}