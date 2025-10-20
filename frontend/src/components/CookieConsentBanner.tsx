import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';

const CookieConsentBanner: React.FC = () => {
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    const consent = localStorage.getItem('cookie_consent_analytics');

    // 未設定の場合のみバナーを表示
    if (consent === null) {
      setShowBanner(true);
    }
  }, []);

  const handleAccept = () => {
    localStorage.setItem('cookie_consent_analytics', 'granted');
    setShowBanner(false);
    // 実際の初期化はAnalyticsProviderが担当
    window.dispatchEvent(new Event('cookie-consent-updated'));
  };

  const handleReject = () => {
    localStorage.setItem('cookie_consent_analytics', 'denied');
    setShowBanner(false);
    // 実際の処理はAnalyticsProviderが担当
    window.dispatchEvent(new Event('cookie-consent-updated'));
  };

  if (!showBanner) {
    return null;
  }

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-gray-900 text-white p-4 shadow-lg z-50">
      <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="flex-1 text-sm">
          <p>
            当サービスでは、サービス改善のためにCookieを使用してアクセス解析を行っています。
            <Link to="/privacy" className="underline ml-1 hover:text-gray-300">
              プライバシーポリシー
            </Link>
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={handleReject}
            className="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded text-sm transition-colors"
          >
            拒否する
          </button>
          <button
            onClick={handleAccept}
            className="px-4 py-2 bg-green-600 hover:bg-green-700 rounded text-sm transition-colors"
          >
            同意する
          </button>
        </div>
      </div>
    </div>
  );
};

export default CookieConsentBanner;
