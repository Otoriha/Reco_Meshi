import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { lineLoginWithCode } from '../../api/auth';

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

      // 3. state検証（CSRF対策）
      const savedState = sessionStorage.getItem('line_state');
      if (state !== savedState) {
        setError('認証状態が一致しません');
        setTimeout(() => navigate('/login'), 3000);
        return;
      }

      // 4. nonce取得
      const nonce = sessionStorage.getItem('line_nonce');
      if (!nonce) {
        setError('認証情報が見つかりません');
        setTimeout(() => navigate('/login'), 3000);
        return;
      }

      // 5. バックエンドでコード交換＆ログイン
      try {
        await lineLoginWithCode({
          code,
          nonce,
          redirectUri: import.meta.env.VITE_LINE_LOGIN_CALLBACK_URL
        });

        // 6. クリーンアップ
        sessionStorage.removeItem('line_nonce');
        sessionStorage.removeItem('line_state');

        // 7. ダッシュボードへリダイレクト
        navigate('/dashboard', { replace: true });
      } catch (err) {
        console.error('LINE login failed:', err);
        setError(err instanceof Error ? err.message : 'ログインに失敗しました');
        setTimeout(() => navigate('/login'), 3000);
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
