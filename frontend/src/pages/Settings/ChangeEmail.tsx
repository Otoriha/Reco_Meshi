import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { changeEmail, getUserProfile } from '../../api/users';
import type { UserProfile } from '../../api/users';
import { useToast } from '../../hooks/useToast';
import { useAuth } from '../../hooks/useAuth';

const ChangeEmail: React.FC = () => {
  const navigate = useNavigate();
  const { showToast } = useToast();
  const { logout } = useAuth();

  const [currentEmail, setCurrentEmail] = useState<string>('');
  const [formData, setFormData] = useState({
    email: '',
    currentPassword: '',
  });
  const [loading, setLoading] = useState(false);
  const [profileLoading, setProfileLoading] = useState(true);
  const [errors, setErrors] = useState<{ [key: string]: string[] }>({});

  // ページ読み込み時にユーザープロフィールを取得
  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const profile: UserProfile = await getUserProfile();
        setCurrentEmail(profile.email);
      } catch (error) {
        const err = error as { response?: { status?: number } };
        if (err.response?.status === 401) {
          showToast('セッションが切れました。再度ログインしてください', 'error');
          logout();
        } else {
          showToast('プロフィール取得に失敗しました', 'error');
        }
      } finally {
        setProfileLoading(false);
      }
    };

    fetchProfile();
  }, [logout, showToast]);

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

    // 同一メール確認
    if (formData.email === currentEmail) {
      setErrors({ email: ['新しいメールアドレスが現在のアドレスと同じです'] });
      showToast('新しいメールアドレスを入力してください', 'error');
      setLoading(false);
      return;
    }

    try {
      const response = await changeEmail({
        email: formData.email,
        current_password: formData.currentPassword,
      });

      showToast(response.message, 'success');

      // メールアドレス変更成功画面へナビゲート
      navigate('/settings/email-confirmation', {
        state: { unconfirmedEmail: response.unconfirmedEmail },
      });
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
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('メールアドレスの変更に失敗しました', 'error');
      }
    } finally {
      setLoading(false);
    }
  };

  if (profileLoading) {
    return (
      <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto mb-4"></div>
          <p className="text-gray-600">読み込み中...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-white rounded-lg shadow p-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">メールアドレスを変更</h1>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="currentEmail" className="block text-sm font-medium text-gray-700 mb-2">
              現在のメールアドレス
            </label>
            <input
              type="email"
              id="currentEmail"
              value={currentEmail}
              disabled
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-gray-600 cursor-not-allowed"
            />
          </div>
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
              新しいメールアドレス
            </label>
            <input
              type="email"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleInputChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="new-email@example.com"
            />
            {errors.email && (
              <p className="text-xs text-red-600 mt-1">{errors.email.join(', ')}</p>
            )}
          </div>

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
              placeholder="パスワードを入力"
            />
            {errors.current_password && (
              <p className="text-xs text-red-600 mt-1">{errors.current_password.join(', ')}</p>
            )}
          </div>

          <div className="bg-blue-50 p-4 rounded-lg">
            <p className="text-sm text-blue-800">
              メールアドレス変更後、新しいメールアドレスへ確認メールが送信されます。
              メール内のリンクをクリックして確認を完了してください。
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

export default ChangeEmail;
