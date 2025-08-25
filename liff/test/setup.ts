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

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => createMockAxiosInstance()),
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
  },
}))

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

// 環境変数のモック
vi.stubEnv('VITE_LIFF_ID', '2007895268-QyEmzdxA')
vi.stubEnv('VITE_API_URL', 'http://localhost:3000/api/v1')

// locationのモック
Object.defineProperty(window, 'location', {
  value: {
    href: 'http://localhost:3002/',
  },
  writable: true,
})

export { mockLiff, mockAxiosInstance }