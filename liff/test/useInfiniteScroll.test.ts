import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useInfiniteScroll } from '../src/hooks/useInfiniteScroll'

// react-intersection-observerをモック
vi.mock('react-intersection-observer', () => ({
  useInView: vi.fn()
}))

const mockUseInView = vi.mocked(await import('react-intersection-observer')).useInView

describe('useInfiniteScroll', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.clearAllTimers()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.runOnlyPendingTimers()
    vi.useRealTimers()
  })

  it('hasNextPageがfalseの場合はonLoadMoreが呼ばれない', () => {
    const onLoadMore = vi.fn()
    let inViewCallback: (inView: boolean) => void = () => {}
    
    mockUseInView.mockImplementation(({ onChange }) => {
      inViewCallback = onChange!
      return { ref: vi.fn(), inView: false }
    })

    renderHook(() => useInfiniteScroll({
      hasNextPage: false,
      isLoading: false,
      onLoadMore
    }))

    act(() => {
      inViewCallback(true)
    })

    expect(onLoadMore).not.toHaveBeenCalled()
  })

  it('isLoadingがtrueの場合はonLoadMoreが呼ばれない', () => {
    const onLoadMore = vi.fn()
    let inViewCallback: (inView: boolean) => void = () => {}
    
    mockUseInView.mockImplementation(({ onChange }) => {
      inViewCallback = onChange!
      return { ref: vi.fn(), inView: false }
    })

    renderHook(() => useInfiniteScroll({
      hasNextPage: true,
      isLoading: true,
      onLoadMore
    }))

    act(() => {
      inViewCallback(true)
    })

    expect(onLoadMore).not.toHaveBeenCalled()
  })

  it('条件が満たされた場合にonLoadMoreが1回だけ呼ばれる', () => {
    const onLoadMore = vi.fn()
    let inViewCallback: (inView: boolean) => void = () => {}
    
    mockUseInView.mockImplementation(({ onChange }) => {
      inViewCallback = onChange!
      return { ref: vi.fn(), inView: false }
    })

    renderHook(() => useInfiniteScroll({
      hasNextPage: true,
      isLoading: false,
      onLoadMore
    }))

    act(() => {
      inViewCallback(true)
    })

    expect(onLoadMore).toHaveBeenCalledTimes(1)
  })

  it('スロットリング機能により短時間での連続呼び出しを防ぐ', () => {
    const onLoadMore = vi.fn()
    let inViewCallback: (inView: boolean) => void = () => {}
    
    mockUseInView.mockImplementation(({ onChange }) => {
      inViewCallback = onChange!
      return { ref: vi.fn(), inView: false }
    })

    renderHook(() => useInfiniteScroll({
      hasNextPage: true,
      isLoading: false,
      onLoadMore,
      throttleMs: 500
    }))

    // 最初の呼び出し（即座に実行される）
    act(() => {
      inViewCallback(true)
    })
    expect(onLoadMore).toHaveBeenCalledTimes(1)

    // 200ms後の呼び出し（スロットリングされる）
    act(() => {
      vi.advanceTimersByTime(200)
      inViewCallback(true)
    })
    expect(onLoadMore).toHaveBeenCalledTimes(1) // まだ1回のまま

    // スロットリング期間を過ぎてから実行される
    act(() => {
      vi.advanceTimersByTime(300) // 合計500ms経過
    })
    expect(onLoadMore).toHaveBeenCalledTimes(2) // 2回目が実行される
  })

  it('スロットリング中の複数呼び出しは最後の1回のみ実行される', () => {
    const onLoadMore = vi.fn()
    let inViewCallback: (inView: boolean) => void = () => {}
    
    mockUseInView.mockImplementation(({ onChange }) => {
      inViewCallback = onChange!
      return { ref: vi.fn(), inView: false }
    })

    renderHook(() => useInfiniteScroll({
      hasNextPage: true,
      isLoading: false,
      onLoadMore,
      throttleMs: 500
    }))

    // 最初の呼び出し
    act(() => {
      inViewCallback(true)
    })
    expect(onLoadMore).toHaveBeenCalledTimes(1)

    // スロットリング期間中の複数呼び出し
    act(() => {
      vi.advanceTimersByTime(100)
      inViewCallback(true) // タイマーがセット
      vi.advanceTimersByTime(100)
      inViewCallback(true) // 前のタイマーがキャンセルされ、新しいタイマーがセット
      vi.advanceTimersByTime(100)
      inViewCallback(true) // また前のタイマーがキャンセルされる
    })

    // 最後のタイマーが実行される
    act(() => {
      vi.advanceTimersByTime(200) // 最後の呼び出しから300ms後
    })
    
    expect(onLoadMore).toHaveBeenCalledTimes(2) // 初回 + 最後のタイマー分のみ
  })

  it('カスタムthresholdとrootMarginが正しく渡される', () => {
    const onLoadMore = vi.fn()
    
    mockUseInView.mockImplementation(() => ({
      ref: vi.fn(),
      inView: false
    }))

    renderHook(() => useInfiniteScroll({
      hasNextPage: true,
      isLoading: false,
      onLoadMore,
      threshold: 0.5,
      rootMargin: '200px'
    }))

    expect(mockUseInView).toHaveBeenCalledWith(
      expect.objectContaining({
        threshold: 0.5,
        rootMargin: '200px'
      })
    )
  })

  it('デフォルトパラメータが正しく設定される', () => {
    const onLoadMore = vi.fn()
    
    mockUseInView.mockImplementation(() => ({
      ref: vi.fn(),
      inView: false
    }))

    renderHook(() => useInfiniteScroll({
      hasNextPage: true,
      isLoading: false,
      onLoadMore
    }))

    expect(mockUseInView).toHaveBeenCalledWith(
      expect.objectContaining({
        threshold: 0.1,
        rootMargin: '100px'
      })
    )
  })
})