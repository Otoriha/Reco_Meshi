/* eslint-disable react-refresh/only-export-components */
import React, { createContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import { grantConsent, revokeConsent } from '../utils/analytics';

type ConsentStatus = 'granted' | 'denied' | 'pending';

interface AnalyticsContextType {
  consentStatus: ConsentStatus;
  updateConsent: (status: 'granted' | 'denied') => void;
}

export const AnalyticsContext = createContext<AnalyticsContextType | undefined>(undefined);

interface AnalyticsProviderProps {
  children: ReactNode;
}

export const AnalyticsProvider: React.FC<AnalyticsProviderProps> = ({ children }) => {
  const [consentStatus, setConsentStatus] = useState<ConsentStatus>('pending');

  // 初期化処理（マウント時とカスタムイベント発火時）
  const initializeFromStorage = () => {
    const consent = localStorage.getItem('cookie_consent_analytics');

    if (consent === 'granted') {
      setConsentStatus('granted');
      // GA4を初期化（重複チェックはanalytics.ts内で実施）
      grantConsent();
    } else if (consent === 'denied') {
      setConsentStatus('denied');
      revokeConsent();
    } else {
      setConsentStatus('pending');
    }
  };

  useEffect(() => {
    // 初回マウント時
    initializeFromStorage();

    // バナーからのイベントをリッスン
    const handleConsentUpdate = () => {
      initializeFromStorage();
    };

    window.addEventListener('cookie-consent-updated', handleConsentUpdate);
    return () => {
      window.removeEventListener('cookie-consent-updated', handleConsentUpdate);
    };
  }, []);

  const updateConsent = (status: 'granted' | 'denied') => {
    localStorage.setItem('cookie_consent_analytics', status);
    setConsentStatus(status);

    if (status === 'granted') {
      grantConsent();
    } else {
      revokeConsent();
    }
  };

  return (
    <AnalyticsContext.Provider value={{ consentStatus, updateConsent }}>
      {children}
    </AnalyticsContext.Provider>
  );
};
