import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate, useSearchParams } from 'react-router-dom';
import { confirmEmail } from '../../api/users';
import { useToast } from '../../hooks/useToast';
import { useAuth } from '../../hooks/useAuth';

const EmailConfirmationSuccess: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { showToast } = useToast();
  const { logout } = useAuth();
  const [searchParams] = useSearchParams();

  const [state, setState] = useState<'pending' | 'loading' | 'success' | 'error'>('pending');
  const [unconfirmedEmail, setUnconfirmedEmail] = useState<string>('');
  const [confirmedEmail, setConfirmedEmail] = useState<string>('');
  const [errorMessage, setErrorMessage] = useState<string>('');

  useEffect(() => {
    const token = searchParams.get('confirmation_token');
    const locationState = location.state as { unconfirmedEmail?: string } | null;

    if (locationState?.unconfirmedEmail) {
      // メールアドレス変更ページから遷移した場合
      setUnconfirmedEmail(locationState.unconfirmedEmail);
    }

    if (token) {
      // メール内のリンクをクリックして遷移した場合
      handleConfirmation(token);
    }
  }, [searchParams, location]);

  const handleConfirmation = async (token: string) => {
    setState('loading');

    try {
      const response = await confirmEmail(token);
      setConfirmedEmail(response.email);
      setUnconfirmedEmail(response.email);
      setState('success');
      showToast('メールアドレスが確認されました', 'success');
    } catch (error) {
      const err = error as {
        response?: {
          status?: number;
          data?: { message?: string };
        }
      };

      if (err.response?.status === 401) {
        setErrorMessage('セッションが切れました。再度ログインしてください');
        logout();
      } else if (err.response?.status === 422) {
        setErrorMessage(
          err.response.data?.message ||
          'トークンが無効またはメールアドレスが既に確認されています'
        );
      } else {
        setErrorMessage('メールアドレスの確認に失敗しました');
      }
      setState('error');
      showToast(errorMessage, 'error');
    }
  };

  if (state === 'loading') {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto mb-4"></div>
          <p className="text-gray-600">メールアドレスを確認中...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-white rounded-lg shadow p-8">
        {state === 'success' ? (
          <>
            <div className="text-center mb-6">
              <div className="inline-flex items-center justify-center h-16 w-16 rounded-full bg-green-100 mb-4">
                <svg
                  className="h-8 w-8 text-green-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </div>
            </div>

            <h1 className="text-2xl font-bold text-gray-900 text-center mb-4">
              メールアドレス確認完了
            </h1>

            <div className="bg-green-50 p-4 rounded-lg mb-6">
              <p className="text-sm text-green-800 text-center">
                メールアドレスが確認されました。新しいメールアドレス：
              </p>
              <p className="text-sm font-medium text-green-900 text-center mt-2 break-all">
                {confirmedEmail || unconfirmedEmail}
              </p>
            </div>

            <p className="text-gray-600 text-center mb-6">
              メールアドレスの変更が完了しました。今後はこのメールアドレスでログインしてください。
            </p>

            <button
              onClick={() => navigate('/settings')}
              className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
            >
              設定ページに戻る
            </button>
          </>
        ) : (
          <>
            <div className="text-center mb-6">
              <div className="inline-flex items-center justify-center h-16 w-16 rounded-full bg-red-100 mb-4">
                <svg
                  className="h-8 w-8 text-red-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </div>
            </div>

            <h1 className="text-2xl font-bold text-gray-900 text-center mb-4">
              確認に失敗しました
            </h1>

            <div className="bg-red-50 p-4 rounded-lg mb-6">
              <p className="text-sm text-red-800">
                {errorMessage ||
                  'メールアドレスの確認中にエラーが発生しました。'}
              </p>
            </div>

            <p className="text-gray-600 text-center text-sm mb-6">
              トークンが無効か有効期限切れの可能性があります。
              新しいメールを再送信するか、設定画面から再度メールアドレスを変更してください。
            </p>

            <div className="flex gap-4">
              <button
                onClick={() => navigate('/settings')}
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700 font-medium"
              >
                戻る
              </button>
              <button
                onClick={() => navigate('/settings/change-email')}
                className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
              >
                再度変更
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default EmailConfirmationSuccess;
