import ReactGA from 'react-ga4';

// 初期化済みフラグ（重複初期化防止）
let isGAInitialized = false;

/**
 * gtagのローカル参照
 * Window拡張により型安全にアクセス可能
 */
const getGtag = (): GtagFunction | undefined => {
  return window.gtag;
};

/**
 * dataLayerとgtagスタブの初期化
 * このモジュールのロード時に自動実行
 */
const initializeGtagStub = (): void => {
  // dataLayerが未定義の場合のみ初期化
  if (!window.dataLayer) {
    window.dataLayer = [];
  }

  // gtagが未定義の場合のみスタブを設定
  if (!window.gtag) {
    window.gtag = function gtag(...args: unknown[]): void {
      window.dataLayer.push(args);
    } as GtagFunction;
  }

  // Consent Mode のデフォルト値を先行設定
  const gtag = getGtag();
  if (gtag) {
    gtag('consent', 'default', {
      analytics_storage: 'denied',
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      wait_for_update: 500,
    });
  }
};

// モジュールロード時にスタブを初期化
initializeGtagStub();

/**
 * GA4の初期化
 * 本番環境かつ測定IDが設定されている場合のみ実行
 */
export const initializeGA = (): void => {
  const measurementId = import.meta.env.VITE_GA_MEASUREMENT_ID;

  // 本番環境かつ測定IDが設定されている場合のみ初期化
  if (!import.meta.env.PROD || !measurementId) {
    return;
  }

  // 既に初期化済みの場合は何もしない（重複初期化防止）
  if (isGAInitialized) {
    console.warn('GA4 is already initialized');
    return;
  }

  // ReactGA.initializeを実行
  ReactGA.initialize(measurementId);
  isGAInitialized = true;
};

/**
 * 同意を付与してGA4を初期化
 */
export const grantConsent = (): void => {
  const gtag = getGtag();
  if (gtag) {
    // Consent Modeを更新
    gtag('consent', 'update', {
      analytics_storage: 'granted',
      ad_storage: 'denied', // 広告は拒否のまま
      ad_user_data: 'denied',
      ad_personalization: 'denied',
    });
  }

  // GA4を初期化（まだ初期化されていない場合）
  initializeGA();
};

/**
 * 同意を撤回してGA関連クッキーを削除
 */
export const revokeConsent = (): void => {
  const gtag = getGtag();
  if (gtag) {
    // Consent Modeを拒否状態に戻す
    gtag('consent', 'update', {
      analytics_storage: 'denied',
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
    });
  }

  // GA関連クッキーをすべて削除
  deleteAllGACookies();
};

/**
 * GA関連クッキーの完全削除
 */
const deleteAllGACookies = (): void => {
  const hostname = location.hostname;
  const domain = hostname.startsWith('www.') ? hostname.substring(4) : hostname;

  // GA4関連のクッキー名パターン
  const gaCookiePatterns = ['_ga', '_gid', '_gat', '_gat_gtag'];

  document.cookie.split(';').forEach((cookie) => {
    const cookieName = cookie.trim().split('=')[0];

    // GAクッキーかチェック
    const isGACookie = gaCookiePatterns.some((pattern) => cookieName.startsWith(pattern));

    if (isGACookie) {
      // 複数のパターンで削除を試みる
      const deletePaths = ['/', ''];
      const deleteDomains = ['', `.${domain}`, `.${hostname}`];

      deletePaths.forEach((path) => {
        deleteDomains.forEach((dom) => {
          const domainPart = dom ? `domain=${dom};` : '';
          const pathPart = path ? `path=${path};` : '';
          document.cookie = `${cookieName}=;${domainPart}${pathPart}expires=Thu, 01 Jan 1970 00:00:00 UTC`;
        });
      });
    }
  });
};

/**
 * ページビューをトラッキング
 */
export const trackPageView = (path: string, title?: string): void => {
  const measurementId = import.meta.env.VITE_GA_MEASUREMENT_ID;

  // 本番環境かつ測定IDが設定されている場合のみトラッキング
  if (!import.meta.env.PROD || !measurementId) {
    return;
  }

  // 初期化されていない場合は何もしない
  if (!isGAInitialized) {
    return;
  }

  // ReactGA経由でページビューを送信
  ReactGA.send({ hitType: 'pageview', page: path, title });
};

/**
 * GA4の初期化状態を取得
 */
export const isInitialized = (): boolean => {
  return isGAInitialized;
};
