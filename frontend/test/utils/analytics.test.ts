import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import ReactGA from 'react-ga4';
import type { GtagFunction } from '../../src/types/analytics';

// ReactGAをモック
vi.mock('react-ga4', () => ({
  default: {
    initialize: vi.fn(),
    send: vi.fn(),
  },
}));

// analytics.tsをインポートする前に環境変数とグローバルオブジェクトをセットアップ
const setupEnvironment = (isProd: boolean, measurementId?: string) => {
  // import.meta.envのモック
  vi.stubGlobal('import.meta', {
    env: {
      PROD: isProd,
      VITE_GA_MEASUREMENT_ID: measurementId,
    },
  });

  // windowオブジェクトの初期化
  if (!window.dataLayer) {
    window.dataLayer = [];
  }
  if (!window.gtag) {
    window.gtag = vi.fn((...args: unknown[]) => {
      window.dataLayer.push(args);
    }) as GtagFunction;
  }
};

describe('analytics', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // dataLayerをクリア
    if (window.dataLayer) {
      window.dataLayer.length = 0;
    }
    // cookieをクリア
    document.cookie.split(';').forEach((cookie) => {
      const name = cookie.trim().split('=')[0];
      document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/`;
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  describe('初期化', () => {
    it('本番環境かつ測定ID設定済みの場合にGA4が初期化される', async () => {
      setupEnvironment(true, 'G-TEST123');

      // 動的インポートで再読み込み
      const analytics = await import('../../src/utils/analytics');
      analytics.initializeGA();

      expect(ReactGA.initialize).toHaveBeenCalledWith('G-TEST123');
    });

    it('開発環境では初期化されない', async () => {
      setupEnvironment(false, 'G-TEST123');

      const analytics = await import('../../src/utils/analytics');
      analytics.initializeGA();

      expect(ReactGA.initialize).not.toHaveBeenCalled();
    });

    it('測定ID未設定では初期化されない', async () => {
      setupEnvironment(true, undefined);

      const analytics = await import('../../src/utils/analytics');
      analytics.initializeGA();

      expect(ReactGA.initialize).not.toHaveBeenCalled();
    });
  });

  describe('grantConsent', () => {
    it('Consent Modeをgrantedに更新する', async () => {
      setupEnvironment(true, 'G-TEST123');

      // window.gtagが呼ばれたことを確認するためのspy
      if (window.gtag) {
        const gtagSpy = vi.spyOn(window as { gtag: GtagFunction }, 'gtag');

        const analytics = await import('../../src/utils/analytics');
        analytics.grantConsent();

        expect(gtagSpy).toHaveBeenCalledWith('consent', 'update', {
          analytics_storage: 'granted',
          ad_storage: 'denied',
          ad_user_data: 'denied',
          ad_personalization: 'denied',
        });
      }
    });
  });

  describe('trackPageView', () => {
    it('本番環境かつ初期化済みの場合にページビューを送信する', async () => {
      setupEnvironment(true, 'G-TEST123');

      const analytics = await import('../../src/utils/analytics');
      analytics.initializeGA();
      analytics.trackPageView('/test', 'Test Page');

      expect(ReactGA.send).toHaveBeenCalledWith({
        hitType: 'pageview',
        page: '/test',
        title: 'Test Page',
      });
    });

    it('開発環境では送信されない', async () => {
      setupEnvironment(false, 'G-TEST123');

      const analytics = await import('../../src/utils/analytics');
      analytics.trackPageView('/test', 'Test Page');

      expect(ReactGA.send).not.toHaveBeenCalled();
    });
  });

  describe('isInitialized', () => {
    it('初期化前はfalseを返す', async () => {
      setupEnvironment(true, 'G-TEST123');

      const analytics = await import('../../src/utils/analytics');
      expect(analytics.isInitialized()).toBe(false);
    });

    it('初期化後はtrueを返す', async () => {
      setupEnvironment(true, 'G-TEST123');

      const analytics = await import('../../src/utils/analytics');
      analytics.initializeGA();
      expect(analytics.isInitialized()).toBe(true);
    });
  });
});
