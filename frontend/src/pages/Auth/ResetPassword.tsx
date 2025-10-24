import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { resetPassword } from '../../api/auth';
import type { ResetPasswordData } from '../../api/auth';

type PageState = 'pending' | 'ready' | 'submitting' | 'error';

const ResetPassword: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [state, setState] = useState<PageState>('pending');
  const [resetPasswordToken, setResetPasswordToken] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showPasswordConfirmation, setShowPasswordConfirmation] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  // トークン検証と初期化
  useEffect(() => {
    const token = searchParams.get('reset_password_token');

    if (!token) {
      setState('error');
      setErrorMessage('パスワードリセットリンクが無効です。再度パスワードリセットを申請してください。');
    } else {
      setResetPasswordToken(token);
      setState('ready');
    }
  }, [searchParams]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // エラー状態からの再送信の場合、エラーメッセージをクリア
    if (state === 'error' && resetPasswordToken) {
      setErrorMessage('');
    }

    // フロント側バリデーション: パスワード不一致
    if (password !== passwordConfirmation) {
      setErrorMessage('パスワードが一致しません');
      setState('error');
      return;
    }

    // フロント側バリデーション: パスワード長
    if (password.length < 6) {
      setErrorMessage('パスワードは6文字以上で入力してください');
      setState('error');
      return;
    }

    // submitting状態へ遷移
    setState('submitting');
    setErrorMessage('');

    try {
      const resetData: ResetPasswordData = {
        password: password,
        password_confirmation: passwordConfirmation,
        reset_password_token: resetPasswordToken,
      };

      await resetPassword(resetData);

      navigate('/password/reset/success', {
        state: { success: true },
        replace: true,
      });
    } catch (error) {
      const err = error as {
        response?: {
          status?: number;
          data?: { errors?: string[]; message?: string };
        };
      };

      let errorMsg = 'パスワードの変更に失敗しました';

      if (err.response?.status === 422) {
        const errorList = err.response.data?.errors || [];
        errorMsg = errorList.length > 0
          ? errorList[0]
          : err.response.data?.message || errorMsg;
      }

      setErrorMessage(errorMsg);
      setState('error');
    }
  };

  // トークンエラー状態（トークンなし）
  if (state === 'error' && !resetPasswordToken) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="max-w-md w-full bg-white rounded-lg shadow p-6">
          <div className="text-center">
            <div className="mb-4">
              <svg
                className="mx-auto h-12 w-12 text-red-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
            </div>
            <p className="text-red-600 mb-6">{errorMessage}</p>
            <button
              onClick={() => navigate('/password/forgot')}
              className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700"
            >
              パスワードリセットを再申請
            </button>
          </div>
        </div>
      </div>
    );
  }

  // フォーム表示（ready, submitting, error（トークンあり））
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="max-w-md w-full bg-white rounded-lg shadow p-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          新しいパスワードの設定
        </h1>

        {/* エラーメッセージ（バリデーションエラーまたはAPI失敗） */}
        {state === 'error' && errorMessage && resetPasswordToken && (
          <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
            {errorMessage}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* パスワード入力 */}
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
              新しいパスワード（6文字以上）
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={state === 'submitting'}
                minLength={6}
                placeholder="6文字以上"
                className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 disabled:bg-gray-100"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                disabled={state === 'submitting'}
                aria-label={showPassword ? 'パスワードを非表示' : 'パスワードを表示'}
                className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
              >
                {showPassword ? (
                  <svg
                    className="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21"
                    />
                  </svg>
                ) : (
                  <svg
                    className="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                    />
                  </svg>
                )}
              </button>
            </div>
          </div>

          {/* パスワード確認 */}
          <div>
            <label htmlFor="password-confirmation" className="block text-sm font-medium text-gray-700 mb-2">
              パスワード確認
            </label>
            <div className="relative">
              <input
                id="password-confirmation"
                type={showPasswordConfirmation ? 'text' : 'password'}
                value={passwordConfirmation}
                onChange={(e) => setPasswordConfirmation(e.target.value)}
                required
                disabled={state === 'submitting'}
                minLength={6}
                placeholder="もう一度入力"
                className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 disabled:bg-gray-100"
              />
              <button
                type="button"
                onClick={() => setShowPasswordConfirmation(!showPasswordConfirmation)}
                disabled={state === 'submitting'}
                aria-label={
                  showPasswordConfirmation ? 'パスワードを非表示' : 'パスワードを表示'
                }
                className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
              >
                {showPasswordConfirmation ? (
                  <svg
                    className="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21"
                    />
                  </svg>
                ) : (
                  <svg
                    className="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                    />
                  </svg>
                )}
              </button>
            </div>
          </div>

          {/* 送信ボタン */}
          <button
            type="submit"
            disabled={state === 'submitting'}
            className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {state === 'submitting' ? (
              <div className="flex items-center justify-center">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                変更中...
              </div>
            ) : (
              'パスワードを変更'
            )}
          </button>
        </form>

        <div className="mt-4 text-center">
          <button
            type="button"
            onClick={() => navigate('/login')}
            className="text-sm text-green-600 hover:underline"
            disabled={state === 'submitting'}
          >
            ログイン画面に戻る
          </button>
        </div>
      </div>
    </div>
  );
};

export default ResetPassword;
