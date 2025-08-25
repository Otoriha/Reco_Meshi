import { getIdTokenExp, isIdTokenExpiringSoon, buildLiffDeepLink } from '../src/utils/auth'
import { mockLiff } from './setup'

describe('Auth Utils', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('getIdTokenExp', () => {
    test('IDトークンの有効期限を取得', () => {
      const mockExp = Math.floor(Date.now() / 1000) + 3600 // 1時間後
      mockLiff.getDecodedIDToken.mockReturnValue({ exp: mockExp })
      
      expect(getIdTokenExp()).toBe(mockExp)
    })

    test('IDトークンがない場合はnullを返す', () => {
      mockLiff.getDecodedIDToken.mockReturnValue(null)
      
      expect(getIdTokenExp()).toBe(null)
    })

    test('expがない場合はnullを返す', () => {
      mockLiff.getDecodedIDToken.mockReturnValue({ sub: 'user-id' })
      
      expect(getIdTokenExp()).toBe(null)
    })

    test('デコード時にエラーが発生した場合はnullを返す', () => {
      mockLiff.getDecodedIDToken.mockImplementation(() => {
        throw new Error('Token decode error')
      })
      
      expect(getIdTokenExp()).toBe(null)
    })
  })

  describe('isIdTokenExpiringSoon', () => {
    beforeEach(() => {
      // Date.now()を固定
      vi.useFakeTimers()
      vi.setSystemTime(new Date('2024-01-01T00:00:00Z'))
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    test('デフォルト60秒以内に期限切れの場合はtrue', () => {
      const currentTime = Math.floor(Date.now() / 1000)
      const expiringSoonExp = currentTime + 30 // 30秒後に期限切れ
      
      mockLiff.getDecodedIDToken.mockReturnValue({ exp: expiringSoonExp })
      
      expect(isIdTokenExpiringSoon()).toBe(true)
    })

    test('60秒より後に期限切れの場合はfalse', () => {
      const currentTime = Math.floor(Date.now() / 1000)
      const notExpiringSoonExp = currentTime + 120 // 2分後に期限切れ
      
      mockLiff.getDecodedIDToken.mockReturnValue({ exp: notExpiringSoonExp })
      
      expect(isIdTokenExpiringSoon()).toBe(false)
    })

    test('カスタム秒数での期限チェック', () => {
      const currentTime = Math.floor(Date.now() / 1000)
      const exp = currentTime + 90 // 90秒後に期限切れ
      
      mockLiff.getDecodedIDToken.mockReturnValue({ exp })
      
      expect(isIdTokenExpiringSoon(120)).toBe(true) // 120秒以内なのでtrue
      expect(isIdTokenExpiringSoon(60)).toBe(false)  // 60秒以内ではないのでfalse
    })

    test('既に期限切れの場合はtrue', () => {
      const currentTime = Math.floor(Date.now() / 1000)
      const expiredExp = currentTime - 60 // 1分前に期限切れ
      
      mockLiff.getDecodedIDToken.mockReturnValue({ exp: expiredExp })
      
      expect(isIdTokenExpiringSoon()).toBe(true)
    })

    test('IDトークンがない場合はtrue（期限切れとして扱う）', () => {
      mockLiff.getDecodedIDToken.mockReturnValue(null)
      
      expect(isIdTokenExpiringSoon()).toBe(true)
    })

    test('有効期限が取得できない場合はtrue', () => {
      mockLiff.getDecodedIDToken.mockReturnValue({ sub: 'user-id' })
      
      expect(isIdTokenExpiringSoon()).toBe(true)
    })

    test('ちょうど境界値の場合', () => {
      const currentTime = Math.floor(Date.now() / 1000)
      const boundaryExp = currentTime + 60 // ちょうど60秒後
      
      mockLiff.getDecodedIDToken.mockReturnValue({ exp: boundaryExp })
      
      expect(isIdTokenExpiringSoon()).toBe(true) // 60秒以内（<=）なのでtrue
    })
  })

  describe('buildLiffDeepLink', () => {
    test('正しいLIFFディープリンクを生成', () => {
      const liffId = '1234567890-abcdefgh'
      const expected = 'line://app/1234567890-abcdefgh'
      
      expect(buildLiffDeepLink(liffId)).toBe(expected)
    })

    test('空文字列のLIFF IDでもリンクを生成', () => {
      const liffId = ''
      const expected = 'line://app/'
      
      expect(buildLiffDeepLink(liffId)).toBe(expected)
    })

    test('特殊文字を含むLIFF IDでもリンクを生成', () => {
      const liffId = '1234-5678_abcd.efgh'
      const expected = 'line://app/1234-5678_abcd.efgh'
      
      expect(buildLiffDeepLink(liffId)).toBe(expected)
    })
  })

  describe('統合テスト', () => {
    test('期限間近のトークンを検知してディープリンクを生成', () => {
      // 期限間近のトークン
      const currentTime = Math.floor(Date.now() / 1000)
      const expiringSoonExp = currentTime + 30
      
      mockLiff.getDecodedIDToken.mockReturnValue({ exp: expiringSoonExp })
      
      // 期限チェック
      expect(isIdTokenExpiringSoon()).toBe(true)
      
      // ディープリンク生成（実際の使用場面を想定）
      if (isIdTokenExpiringSoon()) {
        const liffId = '2007895268-QyEmzdxA'
        const deepLink = buildLiffDeepLink(liffId)
        
        expect(deepLink).toBe('line://app/2007895268-QyEmzdxA')
      }
    })

    test('有効なトークンの場合はディープリンク生成不要', () => {
      // 有効なトークン
      const currentTime = Math.floor(Date.now() / 1000)
      const validExp = currentTime + 3600 // 1時間後
      
      mockLiff.getDecodedIDToken.mockReturnValue({ exp: validExp })
      
      // 期限チェック
      expect(isIdTokenExpiringSoon()).toBe(false)
    })
  })
})