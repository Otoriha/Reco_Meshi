import React, { useState, useEffect, useCallback } from 'react';
import { useLocation, useNavigate, useSearchParams } from 'react-router-dom';
import { confirmEmail } from '../../api/users';
import { useToast } from '../../hooks/useToast';
import { useAuth } from '../../hooks/useAuth';

const EmailConfirmationSuccess: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { showToast } = useToast();
  const { isLoggedIn } = useAuth();
  const [searchParams] = useSearchParams();

  const [state, setState] = useState<'pending' | 'awaiting' | 'loading' | 'success' | 'error'>('pending');
  const [unconfirmedEmail, setUnconfirmedEmail] = useState<string>('');
  const [confirmedEmail, setConfirmedEmail] = useState<string>('');
  const [errorMessage, setErrorMessage] = useState<string>('');

  const handleConfirmation = useCallback(async (token: string) => {
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
          data?: { message?: string; errors?: string[] };
        }
      };

      let errorMsg = 'メールアドレスの確認に失敗しました';

      if (err.response?.status === 401) {
        // 未ログイン状態での401エラーの場合、logout()は呼ばない
        // ログイン画面への遷移を明示的に促す
        errorMsg = 'ログインしてください';
        setErrorMessage(errorMsg);
      } else if (err.response?.status === 422) {
        // バリデーションエラー: errorsフィールドを優先的に表示
        const errorList = err.response.data?.errors || [];
        errorMsg = errorList.length > 0
          ? errorList[0]
          : err.response.data?.message ||
            'トークンが無効またはメールアドレスが既に確認されています';
        setErrorMessage(errorMsg);
      } else {
        setErrorMessage(errorMsg);
      }

      setState('error');
      showToast(errorMsg, 'error');
    }
  }, [showToast]);

  useEffect(() => {
    const token = searchParams.get('confirmation_token');
    const locationState = location.state as { unconfirmedEmail?: string } | null;

    if (locationState?.unconfirmedEmail) {
      // メールアドレス変更ページから遷移した場合（確認メール送信直後）
      setUnconfirmedEmail(locationState.unconfirmedEmail);
      setState('awaiting');
    } else if (token) {
      // メール内のリンクをクリックして遷移した場合
      handleConfirmation(token);
    }
  }, [searchParams, location, handleConfirmation]);

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

  if (state === 'awaiting') {
    return (
      <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-md mx-auto bg-white rounded-lg shadow p-8">
          <div className="text-center mb-6">
            <div className="inline-flex items-center justify-center h-16 w-16 rounded-full bg-blue-100 mb-4">
              <svg
                className="h-8 w-8 text-blue-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                />
              </svg>
            </div>
          </div>

          <h1 className="text-2xl font-bold text-gray-900 text-center mb-4">
            確認メールを送信しました
          </h1>

          <div className="bg-blue-50 p-4 rounded-lg mb-6">
            <p className="text-sm text-blue-800 text-center">
              メールアドレス確認用のメールを以下のアドレスに送信しました：
            </p>
            <p className="text-sm font-medium text-blue-900 text-center mt-2 break-all">
              {unconfirmedEmail}
            </p>
          </div>

          <p className="text-gray-600 text-center mb-6">
            メール内のリンクをクリックして、メールアドレスの確認を完了してください。
          </p>

          <div className="p-4 bg-yellow-50 rounded-lg mb-6">
            <p className="text-sm text-yellow-800">
              メールが届かない場合は、迷惑メールフォルダをご確認ください。
              それでも見つからない場合は、設定ページから再度メール送信を試みてください。
            </p>
          </div>

          <button
            onClick={() => navigate('/settings')}
            className="w-full px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 font-medium"
          >
            設定ページに戻る
          </button>
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
              メールアドレスの変更が完了しました。
              {isLoggedIn
                ? '今後はこのメールアドレスでログインしてください。'
                : '新しいメールアドレスでログインしてください。'}
            </p>

            <button
              onClick={() =>
                isLoggedIn ? navigate('/settings') : navigate('/login')
              }
              className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
            >
              {isLoggedIn ? '設定ページに戻る' : 'ログインする'}
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
                onClick={() =>
                  isLoggedIn ? navigate('/settings') : navigate('/login')
                }
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700 font-medium"
              >
                {isLoggedIn ? '戻る' : 'ログインする'}
              </button>
              <button
                onClick={() =>
                  isLoggedIn
                    ? navigate('/settings/change-email')
                    : navigate('/login')
                }
                className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
              >
                {isLoggedIn ? '再度変更' : 'ログイン'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default EmailConfirmationSuccess;
