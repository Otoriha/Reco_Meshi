import React, { useState } from 'react';
import { signup } from '../../api/auth';

type SignupProps = {
  onSwitchToLogin?: () => void;
  onSignupSuccess?: () => void;
};

interface FormData {
  name: string;
  email: string;
  password: string;
  passwordConfirmation: string;
}

interface FormErrors {
  name?: string;
  email?: string;
  password?: string;
  passwordConfirmation?: string;
  general?: string;
}

const Signup: React.FC<SignupProps> = ({ onSwitchToLogin, onSignupSuccess }) => {
  const [formData, setFormData] = useState<FormData>({
    name: '',
    email: '',
    password: '',
    passwordConfirmation: '',
  });

  const [errors, setErrors] = useState<FormErrors>({});
  const [isLoading, setIsLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string>('');

  // バリデーション関数
  const validateField = (name: keyof FormData, value: string): string | undefined => {
    switch (name) {
      case 'name':
        if (!value.trim()) return '名前は必須です。';
        if (value.trim().length < 2) return '名前は2文字以上で入力してください。';
        if (value.trim().length > 50) return '名前は50文字以内で入力してください。';
        break;
      case 'email':
        if (!value.trim()) return 'メールアドレスは必須です。';
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(value)) return '正しいメールアドレスを入力してください。';
        break;
      case 'password':
        if (!value) return 'パスワードは必須です。';
        if (value.length < 6) return 'パスワードは6文字以上で入力してください。';
        break;
      case 'passwordConfirmation':
        if (!value) return 'パスワード確認は必須です。';
        if (value !== formData.password) return 'パスワードと一致しません。';
        break;
      default:
        break;
    }
    return undefined;
  };

  // フォームデータ更新
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    
    // リアルタイムバリデーション（エラーがある場合のみ）
    if (errors[name as keyof FormErrors]) {
      const error = validateField(name as keyof FormData, value);
      setErrors(prev => ({ ...prev, [name]: error }));
    }
  };

  // フィールドのblur時バリデーション
  const handleInputBlur = (e: React.FocusEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    const error = validateField(name as keyof FormData, value);
    setErrors(prev => ({ ...prev, [name]: error }));
  };

  // 全フィールドバリデーション
  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};
    let isValid = true;

    (Object.keys(formData) as Array<keyof FormData>).forEach(key => {
      const error = validateField(key, formData[key]);
      if (error) {
        newErrors[key] = error;
        isValid = false;
      }
    });

    setErrors(newErrors);
    return isValid;
  };

  // フォーム送信
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // 成功メッセージをクリア
    setSuccessMessage('');
    
    // バリデーション
    if (!validateForm()) {
      return;
    }

    setIsLoading(true);
    setErrors(prev => ({ ...prev, general: undefined }));

    try {
      await signup({
        name: formData.name.trim(),
        email: formData.email.trim(),
        password: formData.password,
        passwordConfirmation: formData.passwordConfirmation,
      });

      // 成功メッセージを表示
      setSuccessMessage('登録完了しました。ログイン画面に移動します。');
      
      // 2秒後にログイン画面へ遷移
      setTimeout(() => {
        onSignupSuccess?.();
        onSwitchToLogin?.();
      }, 2000);

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '登録に失敗しました。';
      setErrors({ general: errorMessage });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="max-w-md w-full bg-white rounded-lg shadow p-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          新規登録
        </h1>
        
        {/* 成功メッセージ */}
        {successMessage && (
          <div className="mb-4 p-3 bg-green-100 border border-green-400 text-green-700 rounded">
            {successMessage}
          </div>
        )}

        {/* 汎用エラーメッセージ */}
        {errors.general && (
          <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
            {errors.general}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* 名前 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              名前
            </label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              onBlur={handleInputBlur}
              className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                errors.name ? 'border-red-300' : 'border-gray-300'
              }`}
              disabled={isLoading}
            />
            {errors.name && (
              <p className="mt-1 text-sm text-red-600">{errors.name}</p>
            )}
          </div>

          {/* メールアドレス */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              メールアドレス
            </label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleInputChange}
              onBlur={handleInputBlur}
              className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                errors.email ? 'border-red-300' : 'border-gray-300'
              }`}
              disabled={isLoading}
            />
            {errors.email && (
              <p className="mt-1 text-sm text-red-600">{errors.email}</p>
            )}
          </div>

          {/* パスワード */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              パスワード
            </label>
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              onBlur={handleInputBlur}
              className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                errors.password ? 'border-red-300' : 'border-gray-300'
              }`}
              disabled={isLoading}
            />
            {errors.password && (
              <p className="mt-1 text-sm text-red-600">{errors.password}</p>
            )}
          </div>

          {/* パスワード確認 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              パスワード確認
            </label>
            <input
              type="password"
              name="passwordConfirmation"
              value={formData.passwordConfirmation}
              onChange={handleInputChange}
              onBlur={handleInputBlur}
              className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                errors.passwordConfirmation ? 'border-red-300' : 'border-gray-300'
              }`}
              disabled={isLoading}
            />
            {errors.passwordConfirmation && (
              <p className="mt-1 text-sm text-red-600">{errors.passwordConfirmation}</p>
            )}
          </div>

          {/* 送信ボタン */}
          <button
            type="submit"
            disabled={isLoading || !!successMessage}
            className={`w-full py-2 px-4 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 ${
              isLoading || successMessage
                ? 'bg-gray-400 cursor-not-allowed'
                : 'bg-blue-600 hover:bg-blue-700'
            } text-white`}
          >
            {isLoading ? '登録中...' : '新規登録'}
          </button>
        </form>

        {/* ログイン画面への切り替え */}
        <div className="mt-4 text-center text-sm text-gray-600">
          既にアカウントをお持ちの方は{' '}
          <button
            type="button"
            onClick={onSwitchToLogin}
            className="text-blue-600 hover:underline"
            disabled={isLoading}
          >
            ログインはこちら
          </button>
        </div>
      </div>
    </div>
  );
};

export default Signup;