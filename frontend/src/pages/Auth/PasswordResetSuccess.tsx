import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';

type PageState = 'pending' | 'awaiting' | 'success';

const PasswordResetSuccess: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const [state, setState] = useState<PageState>('pending');
  const [email, setEmail] = useState('');

  useEffect(() => {
    const locationState = location.state as { email?: string; success?: boolean } | null;

    if (locationState?.email) {
      // ForgotPasswordから遷移（メール送信直後）
      setEmail(locationState.email);
      setState('awaiting');
    } else if (locationState?.success) {
      // ResetPasswordから遷移（パスワード変更完了）
      setState('success');
    } else {
      // stateがない場合（直接アクセス・リロード等）はログイン画面へ
      navigate('/login', { replace: true });
    }
  }, [location, navigate]);

  // pending状態（リダイレクト処理中）
  if (state === 'pending') {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="max-w-md w-full bg-white rounded-lg shadow p-6">
        {state === 'awaiting' && (
          <>
            <div className="text-center mb-6">
              <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100 mb-4">
                <svg
                  className="h-6 w-6 text-green-600"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                  />
                </svg>
              </div>
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                パスワードリセットメールを送信しました
              </h1>
              <p className="text-gray-600 mb-4">
                {email} 宛にパスワードリセットメールを送信しました。
              </p>
              <p className="text-gray-600 text-sm">
                メール内のリンクをクリックして、新しいパスワードを設定してください。
              </p>
            </div>

            <button
              onClick={() => navigate('/login')}
              className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
            >
              ログイン画面に戻る
            </button>
          </>
        )}

        {state === 'success' && (
          <>
            <div className="text-center mb-6">
              <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100 mb-4">
                <svg
                  className="h-6 w-6 text-green-600"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </div>
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                パスワード変更完了
              </h1>
              <p className="text-gray-600">
                新しいパスワードでログインしてください。
              </p>
            </div>

            <button
              onClick={() => navigate('/login')}
              className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
            >
              ログインする
            </button>
          </>
        )}
      </div>
    </div>
  );
};

export default PasswordResetSuccess;
