import liff from '@line/liff'

export const getIdTokenExp = (): number | null => {
  try {
    const decoded = liff.getDecodedIDToken()
    return decoded?.exp ?? null
  } catch {
    return null
  }
}

export const isIdTokenExpiringSoon = (seconds = 60): boolean => {
  const exp = getIdTokenExp()
  if (!exp) return true
  const now = Math.floor(Date.now() / 1000)
  return exp - now <= seconds
}

export const buildLiffDeepLink = (liffId: string) => `line://app/${liffId}`

