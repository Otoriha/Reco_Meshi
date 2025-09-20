/**
 * nextパラメータが安全な相対パスかどうかを検証する
 * オープンリダイレクト攻撃を防ぐために使用
 */
export const isSafeNextPath = (next: string | null): boolean => {
  if (!next) return false;
  if (!next.startsWith('/')) return false;      // 相対パスのみ許可
  if (next.startsWith('//')) return false;      // スキーム相対URL拒否
  if (/^https?:/i.test(next)) return false;     // 絶対URL拒否
  return true;
};