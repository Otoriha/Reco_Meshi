import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { changePassword } from '../../api/users';
import type { ChangePasswordData } from '../../api/users';
import { useToast } from '../../hooks/useToast';

const ChangePassword: React.FC = () => {
  const navigate = useNavigate();
  const { showToast } = useToast();

  const [formData, setFormData] = useState({
    currentPassword: '',
    newPassword: '',
    newPasswordConfirmation: '',
  });
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<{ [key: string]: string[] }>({});

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
    // 入力時にエラーをクリア
    if (errors[name]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[name];
        return newErrors;
      });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrors({});

    // バリデーション: パスワード一致確認
    if (formData.newPassword !== formData.newPasswordConfirmation) {
      setErrors({ newPasswordConfirmation: ['新しいパスワードが一致しません'] });
      showToast('新しいパスワードが一致しません', 'error');
      setLoading(false);
      return;
    }

    // バリデーション: パスワード長
    if (formData.newPassword.length < 6) {
      setErrors({ newPassword: ['パスワードは6文字以上で入力してください'] });
      showToast('パスワードは6文字以上で入力してください', 'error');
      setLoading(false);
      return;
    }

    try {
      const data: ChangePasswordData = {
        current_password: formData.currentPassword,
        new_password: formData.newPassword,
        new_password_confirmation: formData.newPasswordConfirmation,
      };

      const response = await changePassword(data);
      showToast(response.message, 'success');
      navigate('/settings');
    } catch (error) {
      const err = error as {
        response?: {
          status?: number;
          data?: { errors?: Record<string, string[]> };
        }
      };

      if (err.response?.status === 422) {
        setErrors(err.response.data?.errors || {});
        showToast('入力内容を確認してください', 'error');
      } else if (err.response?.status === 401) {
        showToast('現在のパスワードが正しくありません', 'error');
        setErrors({ currentPassword: ['現在のパスワードが正しくありません'] });
      } else {
        showToast('パスワード変更に失敗しました', 'error');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-white rounded-lg shadow p-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">パスワードを変更</h1>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="currentPassword" className="block text-sm font-medium text-gray-700 mb-2">
              現在のパスワード
            </label>
            <input
              type="password"
              id="currentPassword"
              name="currentPassword"
              value={formData.currentPassword}
              onChange={handleInputChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              disabled={loading}
            />
            {errors.currentPassword && (
              <p className="text-xs text-red-600 mt-1">{errors.currentPassword.join(', ')}</p>
            )}
            {errors.current_password && (
              <p className="text-xs text-red-600 mt-1">{errors.current_password.join(', ')}</p>
            )}
          </div>

          <div>
            <label htmlFor="newPassword" className="block text-sm font-medium text-gray-700 mb-2">
              新しいパスワード
            </label>
            <input
              type="password"
              id="newPassword"
              name="newPassword"
              value={formData.newPassword}
              onChange={handleInputChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              disabled={loading}
            />
            {errors.newPassword && (
              <p className="text-xs text-red-600 mt-1">{errors.newPassword.join(', ')}</p>
            )}
            {errors.new_password && (
              <p className="text-xs text-red-600 mt-1">{errors.new_password.join(', ')}</p>
            )}
            <p className="text-xs text-gray-500 mt-1">6文字以上で入力してください</p>
          </div>

          <div>
            <label htmlFor="newPasswordConfirmation" className="block text-sm font-medium text-gray-700 mb-2">
              パスワード確認
            </label>
            <input
              type="password"
              id="newPasswordConfirmation"
              name="newPasswordConfirmation"
              value={formData.newPasswordConfirmation}
              onChange={handleInputChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              disabled={loading}
            />
            {errors.newPasswordConfirmation && (
              <p className="text-xs text-red-600 mt-1">{errors.newPasswordConfirmation.join(', ')}</p>
            )}
            {errors.new_password_confirmation && (
              <p className="text-xs text-red-600 mt-1">{errors.new_password_confirmation.join(', ')}</p>
            )}
          </div>

          <div className="bg-blue-50 p-4 rounded-lg">
            <p className="text-sm text-blue-800">
              パスワードを変更すると、次回ログイン時から新しいパスワードでログインしてください。
            </p>
          </div>

          <div className="flex gap-4">
            <button
              type="button"
              onClick={() => navigate('/settings')}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700 font-medium disabled:opacity-50"
              disabled={loading}
            >
              キャンセル
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium disabled:bg-gray-400"
              disabled={loading}
            >
              {loading ? '処理中...' : '変更する'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ChangePassword;
