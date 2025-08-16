import React from 'react';

type LoginProps = {
  onSwitchToSignup?: () => void;
};

const Login: React.FC<LoginProps> = ({ onSwitchToSignup }) => {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="max-w-md w-full bg-white rounded-lg shadow p-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          ログイン
        </h1>
        <form className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              メールアドレス
            </label>
            <input
              type="email"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              パスワード
            </label>
            <input
              type="password"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            ログイン
          </button>
        </form>
        <div className="mt-4 text-center text-sm text-gray-600">
          アカウントをお持ちでない方は{' '}
          <button
            type="button"
            onClick={onSwitchToSignup}
            className="text-blue-600 hover:underline"
          >
            新規登録はこちら
          </button>
        </div>
      </div>
    </div>
  );
};

export default Login;