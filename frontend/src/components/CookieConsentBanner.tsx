import React from 'react';
import { Link } from 'react-router-dom';
import { useAnalytics } from '../hooks/useAnalytics';

const CookieConsentBanner: React.FC = () => {
  const { consentStatus, updateConsent } = useAnalytics();

  // consentStatusが'pending'の場合のみバナーを表示
  // 設定ページで同意状態を変更した場合も自動的に反映される
  if (consentStatus !== 'pending') {
    return null;
  }

  const handleAccept = () => {
    updateConsent('granted');
  };

  const handleReject = () => {
    updateConsent('denied');
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
