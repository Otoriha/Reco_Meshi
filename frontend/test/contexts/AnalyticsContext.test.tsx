import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AnalyticsProvider } from '../../src/contexts/AnalyticsContext';
import { useAnalytics } from '../../src/hooks/useAnalytics';
import * as analytics from '../../src/utils/analytics';

// analytics.tsをモック
vi.mock('../../src/utils/analytics', () => ({
  grantConsent: vi.fn(),
  revokeConsent: vi.fn(),
}));

// テスト用コンポーネント
const TestComponent = () => {
  const { consentStatus, updateConsent } = useAnalytics();

  return (
    <div>
      <div data-testid="consent-status">{consentStatus}</div>
      <button data-testid="grant-btn" onClick={() => updateConsent('granted')}>
        Grant
      </button>
      <button data-testid="revoke-btn" onClick={() => updateConsent('denied')}>
        Revoke
      </button>
    </div>
  );
};

describe('AnalyticsContext', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  it('初期状態はpendingである', () => {
    render(
      <AnalyticsProvider>
        <TestComponent />
      </AnalyticsProvider>
    );

    expect(screen.getByTestId('consent-status')).toHaveTextContent('pending');
  });

  it('LocalStorageにgrantedがある場合、初期化時にgrantConsentが呼ばれる', async () => {
    localStorage.setItem('cookie_consent_analytics', 'granted');

    render(
      <AnalyticsProvider>
        <TestComponent />
      </AnalyticsProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('consent-status')).toHaveTextContent('granted');
    });

    expect(analytics.grantConsent).toHaveBeenCalled();
  });

  it('LocalStorageにdeniedがある場合、初期化時にrevokeConsentが呼ばれる', async () => {
    localStorage.setItem('cookie_consent_analytics', 'denied');

    render(
      <AnalyticsProvider>
        <TestComponent />
      </AnalyticsProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('consent-status')).toHaveTextContent('denied');
    });

    expect(analytics.revokeConsent).toHaveBeenCalled();
  });

  it('updateConsentでgrantedに更新できる', async () => {
    render(
      <AnalyticsProvider>
        <TestComponent />
      </AnalyticsProvider>
    );

    const grantBtn = screen.getByTestId('grant-btn');
    grantBtn.click();

    await waitFor(() => {
      expect(screen.getByTestId('consent-status')).toHaveTextContent('granted');
    });

    expect(localStorage.getItem('cookie_consent_analytics')).toBe('granted');
    expect(analytics.grantConsent).toHaveBeenCalled();
  });

  it('updateConsentでdeniedに更新できる', async () => {
    render(
      <AnalyticsProvider>
        <TestComponent />
      </AnalyticsProvider>
    );

    const revokeBtn = screen.getByTestId('revoke-btn');
    revokeBtn.click();

    await waitFor(() => {
      expect(screen.getByTestId('consent-status')).toHaveTextContent('denied');
    });

    expect(localStorage.getItem('cookie_consent_analytics')).toBe('denied');
    expect(analytics.revokeConsent).toHaveBeenCalled();
  });

  it('cookie-consent-updatedイベントで状態が更新される', async () => {
    render(
      <AnalyticsProvider>
        <TestComponent />
      </AnalyticsProvider>
    );

    expect(screen.getByTestId('consent-status')).toHaveTextContent('pending');

    // LocalStorageを更新してイベントを発火
    localStorage.setItem('cookie_consent_analytics', 'granted');
    window.dispatchEvent(new Event('cookie-consent-updated'));

    await waitFor(() => {
      expect(screen.getByTestId('consent-status')).toHaveTextContent('granted');
    });

    expect(analytics.grantConsent).toHaveBeenCalled();
  });
});
