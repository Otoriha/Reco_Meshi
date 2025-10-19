import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { lineLoginWithCode, lineLinkWithCode } from '../../api/auth';

const LineCallback: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [error, setError] = useState<string>('');

  useEffect(() => {
    const handleCallback = async () => {
      // 1. パラメータ取得
      const code = searchParams.get('code');
      const state = searchParams.get('state');
      const errorParam = searchParams.get('error');
      const errorDescription = searchParams.get('error_description');

      // 2. エラーチェック
      if (errorParam) {
        setError(errorDescription || 'LINE認証がキャンセルされました');
        setTimeout(() => navigate('/login'), 3000);
        return;
      }

      if (!code || !state) {
        setError('認証情報が不正です');
        setTimeout(() => navigate('/login'), 3000);
        return;
      }

      // 3. 分岐判定: line_link_nonce があれば連携フロー
      const linkNonce = sessionStorage.getItem('line_link_nonce');
      const linkState = sessionStorage.getItem('line_link_state');
      const loginNonce = sessionStorage.getItem('line_nonce');
      const loginState = sessionStorage.getItem('line_state');

      const isLinkFlow = !!linkNonce;

      if (isLinkFlow) {
        // ===== 連携フロー =====
        // 4. state検証
        if (state !== linkState) {
          setError('認証状態が一致しません');
          setTimeout(() => navigate('/settings'), 3000);
          return;
        }

        try {
          // 5. バックエンドでコード交換＆連携
          await lineLinkWithCode({
            code,
            nonce: linkNonce,
            redirectUri: import.meta.env.VITE_LINE_LOGIN_CALLBACK_URL
          });

          // 6. クリーンアップ
          sessionStorage.removeItem('line_link_nonce');
          sessionStorage.removeItem('line_link_state');

          // 7. Settings画面へリダイレクト
          navigate('/settings', {
            replace: true,
            state: { message: 'LINEアカウントと連携しました' }
          });
        } catch (err) {
          console.error('LINE link failed:', err);
          setError(err instanceof Error ? err.message : '連携に失敗しました');
          setTimeout(() => navigate('/settings'), 3000);
        }
      } else {
        // ===== 既存のログインフロー（変更なし） =====
        if (state !== loginState) {
          setError('認証状態が一致しません');
          setTimeout(() => navigate('/login'), 3000);
          return;
        }

        if (!loginNonce) {
          setError('認証情報が見つかりません');
          setTimeout(() => navigate('/login'), 3000);
          return;
        }

        try {
          await lineLoginWithCode({
            code,
            nonce: loginNonce,
            redirectUri: import.meta.env.VITE_LINE_LOGIN_CALLBACK_URL
          });

          sessionStorage.removeItem('line_nonce');
          sessionStorage.removeItem('line_state');

          navigate('/dashboard', { replace: true });
        } catch (err) {
          console.error('LINE login failed:', err);
          setError(err instanceof Error ? err.message : 'ログインに失敗しました');
          setTimeout(() => navigate('/login'), 3000);
        }
      }
    };

    handleCallback();
  }, [searchParams, navigate]);

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="max-w-md w-full bg-white rounded-lg shadow p-6">
          <div className="text-red-600 mb-4">{error}</div>
          <div className="text-gray-600">ログイン画面に戻ります...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="max-w-md w-full bg-white rounded-lg shadow p-6 text-center">
        <div className="mb-4">LINEログイン処理中...</div>
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto"></div>
      </div>
    </div>
  );
};

export default LineCallback;
