import '@testing-library/jest-dom'
import { vi } from 'vitest'

// sessionStorageのモック
Object.defineProperty(window, 'sessionStorage', {
  value: {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn(),
  },
  writable: true,
})

// localStorageのモック
Object.defineProperty(window, 'localStorage', {
  value: {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn(),
  },
  writable: true,
})

// axiosのモック
const createMockAxiosInstance = () => ({
  request: vi.fn(),
  get: vi.fn(),
  post: vi.fn(),
  put: vi.fn(),
  delete: vi.fn(),
  patch: vi.fn(),
  head: vi.fn(),
  options: vi.fn(),
  defaults: {},
  interceptors: {
    request: {
      use: vi.fn(),
      eject: vi.fn(),
    },
    response: {
      use: vi.fn(),
      eject: vi.fn(),
    },
  },
})

const mockAxiosInstance = createMockAxiosInstance()

// axiosの詳細なモック設定
const mockInterceptors = {
  request: {
    use: vi.fn(),
    eject: vi.fn(),
  },
  response: {
    use: vi.fn(),
    eject: vi.fn(),
  },
}

const createFullMockAxiosInstance = () => ({
  request: vi.fn().mockResolvedValue({ data: 'mock response' }),
  get: vi.fn().mockResolvedValue({ data: 'mock response' }),
  post: vi.fn((url: string) => {
    if (typeof url === 'string' && url.includes('/auth/generate_nonce')) {
      return Promise.resolve({ data: { nonce: 'mock-nonce' } })
    }
    if (typeof url === 'string' && url.includes('/auth/line_login')) {
      return Promise.resolve({
        data: {
          token: 'mock-jwt-token',
          user: {
            userId: 'mock-user-id',
            displayName: 'Mock User',
            pictureUrl: 'https://example.com/avatar.jpg',
          },
        },
      })
    }
    return Promise.resolve({ data: 'mock response' })
  }),
  put: vi.fn().mockResolvedValue({ data: 'mock response' }),
  delete: vi.fn().mockResolvedValue({ data: 'mock response' }),
  patch: vi.fn().mockResolvedValue({ data: 'mock response' }),
  head: vi.fn().mockResolvedValue({ data: 'mock response' }),
  options: vi.fn().mockResolvedValue({ data: 'mock response' }),
  defaults: {
    headers: {},
    timeout: 0,
  },
  interceptors: mockInterceptors,
})

let axiosCreateCallCount = 0
const mockAxiosCreate = vi.fn().mockImplementation(() => {
  axiosCreateCallCount++
  return createFullMockAxiosInstance()
})

vi.mock('axios', () => {
  return {
    default: {
      ...createFullMockAxiosInstance(),
      create: mockAxiosCreate,
    },
  }
})

// LIFFのモック
const mockLiff = {
  init: vi.fn().mockResolvedValue(undefined),
  isLoggedIn: vi.fn().mockReturnValue(true),
  isInClient: vi.fn().mockReturnValue(true),
  getIDToken: vi.fn().mockReturnValue('mock-id-token'),
  getDecodedIDToken: vi.fn().mockReturnValue({ exp: Math.floor(Date.now() / 1000) + 3600 }),
  getProfile: vi.fn().mockResolvedValue({
    userId: 'mock-user-id',
    displayName: 'Mock User',
    pictureUrl: 'https://example.com/avatar.jpg'
  }),
  login: vi.fn(),
  logout: vi.fn(),
}

vi.mock('@line/liff', () => ({
  default: mockLiff,
}))

// console.errorをモック（テスト中のエラーログを抑制）
vi.spyOn(console, 'error').mockImplementation(() => {})
vi.spyOn(console, 'warn').mockImplementation(() => {})

// 環境変数のモック（実際の値を間接的に使用）
const resolvedLiffId = process.env.VITE_LIFF_ID || process.env.LIFF_ID || ''
const resolvedApiUrl = process.env.VITE_API_URL || 'http://localhost:3000/api/v1'
vi.stubEnv('VITE_LIFF_ID', resolvedLiffId)
vi.stubEnv('VITE_API_URL', resolvedApiUrl)

// locationのモック  
Object.defineProperty(window, 'location', {
  value: {
    href: 'http://localhost:3002/',
  },
  writable: true,
})

// window.confirmのモック
Object.defineProperty(window, 'confirm', {
  value: vi.fn().mockReturnValue(false),
  writable: true,
})

export { mockLiff, mockAxiosInstance }

// navigator.clipboard のモック（user-event等が期待）
if (!('clipboard' in navigator)) {
  // @ts-expect-error - ここでclipboardを挿入
  navigator.clipboard = {
    writeText: vi.fn().mockResolvedValue(undefined),
    readText: vi.fn().mockResolvedValue(''),
  }
} else {
  // 既存がある場合もテスト安定のためモック化
  vi.spyOn(navigator, 'clipboard', 'get').mockReturnValue({
    writeText: vi.fn().mockResolvedValue(undefined),
    readText: vi.fn().mockResolvedValue(''),
  } as any)
}

// 一部ライブラリが古いAPIを呼ぶケースのフォールバック
if (!(document as any).execCommand) {
  ;(document as any).execCommand = vi.fn().mockReturnValue(true)
}
