import { describe, it, expect } from 'vitest'
import { isSafeNextPath } from '../../src/utils/validation'

describe('isSafeNextPath', () => {
  it('nullまたは空文字の場合はfalseを返す', () => {
    expect(isSafeNextPath(null)).toBe(false)
    expect(isSafeNextPath('')).toBe(false)
  })

  it('有効な相対パスの場合はtrueを返す', () => {
    expect(isSafeNextPath('/')).toBe(true)
    expect(isSafeNextPath('/ingredients')).toBe(true)
    expect(isSafeNextPath('/recipes/123')).toBe(true)
    expect(isSafeNextPath('/settings?tab=profile')).toBe(true)
    expect(isSafeNextPath('/ingredients#section1')).toBe(true)
  })

  it('相対パス以外で始まる場合はfalseを返す', () => {
    expect(isSafeNextPath('ingredients')).toBe(false)
    expect(isSafeNextPath('recipes/123')).toBe(false)
  })

  it('スキーム相対URLの場合はfalseを返す', () => {
    expect(isSafeNextPath('//evil.com')).toBe(false)
    expect(isSafeNextPath('//example.org/path')).toBe(false)
  })

  it('絶対URLの場合はfalseを返す', () => {
    expect(isSafeNextPath('http://evil.com')).toBe(false)
    expect(isSafeNextPath('https://evil.com')).toBe(false)
    expect(isSafeNextPath('HTTP://EVIL.COM')).toBe(false)
    expect(isSafeNextPath('HTTPS://EVIL.COM')).toBe(false)
  })

  it('ファイルプロトコルの場合はfalseを返す', () => {
    expect(isSafeNextPath('file:///etc/passwd')).toBe(false)
  })

  it('その他のプロトコルの場合はfalseを返す', () => {
    expect(isSafeNextPath('ftp://example.com')).toBe(false)
    expect(isSafeNextPath('javascript:alert("xss")')).toBe(false)
  })
})