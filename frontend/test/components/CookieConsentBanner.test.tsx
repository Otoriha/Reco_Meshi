import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import type { ReactNode } from 'react';
import CookieConsentBanner from '../../src/components/CookieConsentBanner';
import { AnalyticsContext } from '../../src/contexts/AnalyticsContext';

// テスト用のAnalyticsProviderラッパー
const createMockAnalyticsProvider = (consentStatus: 'granted' | 'denied' | 'pending', updateConsent = vi.fn()) => {
  return ({ children }: { children: ReactNode }) => (
    <AnalyticsContext.Provider value={{ consentStatus, updateConsent }}>
      {children}
    </AnalyticsContext.Provider>
  );
};

describe('CookieConsentBanner', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('consentStatusがpendingの場合にバナーが表示される', () => {
    const MockProvider = createMockAnalyticsProvider('pending');

    render(
      <MemoryRouter>
        <MockProvider>
          <CookieConsentBanner />
        </MockProvider>
      </MemoryRouter>
    );

    expect(screen.getByText(/当サービスでは、サービス改善のためにCookieを使用/)).toBeInTheDocument();
    expect(screen.getByText('同意する')).toBeInTheDocument();
    expect(screen.getByText('拒否する')).toBeInTheDocument();
  });

  it('consentStatusがgrantedの場合にバナーが非表示になる', () => {
    const MockProvider = createMockAnalyticsProvider('granted');

    render(
      <MemoryRouter>
        <MockProvider>
          <CookieConsentBanner />
        </MockProvider>
      </MemoryRouter>
    );

    expect(screen.queryByText(/当サービスでは、サービス改善のためにCookieを使用/)).not.toBeInTheDocument();
  });

  it('consentStatusがdeniedの場合にバナーが非表示になる', () => {
    const MockProvider = createMockAnalyticsProvider('denied');

    render(
      <MemoryRouter>
        <MockProvider>
          <CookieConsentBanner />
        </MockProvider>
      </MemoryRouter>
    );

    expect(screen.queryByText(/当サービスでは、サービス改善のためにCookieを使用/)).not.toBeInTheDocument();
  });

  it('同意ボタンをクリックするとupdateConsentが呼ばれる', () => {
    const updateConsentMock = vi.fn();
    const MockProvider = createMockAnalyticsProvider('pending', updateConsentMock);

    render(
      <MemoryRouter>
        <MockProvider>
          <CookieConsentBanner />
        </MockProvider>
      </MemoryRouter>
    );

    const acceptButton = screen.getByText('同意する');
    acceptButton.click();

    expect(updateConsentMock).toHaveBeenCalledWith('granted');
  });

  it('拒否ボタンをクリックするとupdateConsentが呼ばれる', () => {
    const updateConsentMock = vi.fn();
    const MockProvider = createMockAnalyticsProvider('pending', updateConsentMock);

    render(
      <MemoryRouter>
        <MockProvider>
          <CookieConsentBanner />
        </MockProvider>
      </MemoryRouter>
    );

    const rejectButton = screen.getByText('拒否する');
    rejectButton.click();

    expect(updateConsentMock).toHaveBeenCalledWith('denied');
  });

  it('プライバシーポリシーへのリンクが表示される', () => {
    const MockProvider = createMockAnalyticsProvider('pending');

    render(
      <MemoryRouter>
        <MockProvider>
          <CookieConsentBanner />
        </MockProvider>
      </MemoryRouter>
    );

    const privacyLink = screen.getByText('プライバシーポリシー');
    expect(privacyLink).toBeInTheDocument();
    expect(privacyLink).toHaveAttribute('href', '/privacy');
  });

  it('設定ページで同意状態を変更するとバナーが自動的に非表示になる', () => {
    const MockProvider = createMockAnalyticsProvider('pending');

    const { rerender } = render(
      <MemoryRouter>
        <MockProvider>
          <CookieConsentBanner />
        </MockProvider>
      </MemoryRouter>
    );

    // 最初はバナーが表示されている
    expect(screen.getByText(/当サービスでは、サービス改善のためにCookieを使用/)).toBeInTheDocument();

    // consentStatusが変更されたと仮定して再レンダリング
    const UpdatedMockProvider = createMockAnalyticsProvider('granted');
    rerender(
      <MemoryRouter>
        <UpdatedMockProvider>
          <CookieConsentBanner />
        </UpdatedMockProvider>
      </MemoryRouter>
    );

    // バナーが非表示になっている
    expect(screen.queryByText(/当サービスでは、サービス改善のためにCookieを使用/)).not.toBeInTheDocument();
  });
});
