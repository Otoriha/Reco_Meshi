import React, { useState, useEffect } from 'react';
import { getUserProfile, getUserSettings, updateUserProfile, updateUserSettings } from '../../api/users';
import type { UserProfile, UserSettings } from '../../api/users';
import { DIFFICULTY_OPTIONS, COOKING_TIME_OPTIONS, SHOPPING_FREQUENCY_OPTIONS } from '../../constants/settings';
import { useAuth } from '../../hooks/useAuth';

const Settings: React.FC = () => {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [profileForm, setProfileForm] = useState({ name: '' });
  const [loading, setLoading] = useState({ data: true, saving: false });
  const [errors, setErrors] = useState<{ [key: string]: string[] }>({});
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const { logout } = useAuth();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [profileData, settingsData] = await Promise.all([
          getUserProfile(),
          getUserSettings()
        ]);
        setProfile(profileData);
        setSettings(settingsData);
        setProfileForm({ name: profileData.name });
      } catch (error) {
        const err = error as { response?: { status?: number } };
        if (err.response?.status === 401) {
          setMessage({ type: 'error', text: 'セッションが切れました。再度ログインしてください' });
          setTimeout(() => logout(), 2000);
        } else {
          setMessage({ type: 'error', text: 'データの取得に失敗しました' });
        }
      } finally {
        setLoading((prev) => ({ ...prev, data: false }));
      }
    };

    fetchData();
  }, [logout]);

  const handleSave = async () => {
    if (!settings) return;

    setLoading((prev) => ({ ...prev, saving: true }));
    setErrors({});
    setMessage(null);

    try {
      await Promise.all([
        updateUserProfile({ name: profileForm.name }),
        updateUserSettings(settings)
      ]);
      setMessage({ type: 'success', text: '変更を保存しました' });
      if (profile) {
        setProfile({ ...profile, name: profileForm.name });
      }
      setTimeout(() => setMessage(null), 3000);
    } catch (error) {
      const err = error as { response?: { status?: number; data?: { errors?: Record<string, string[]> } } };
      if (err.response?.status === 422) {
        setErrors(err.response.data?.errors || {});
        setMessage({ type: 'error', text: '入力内容を確認してください' });
      } else if (err.response?.status === 401) {
        setMessage({ type: 'error', text: 'セッションが切れました。再度ログインしてください' });
        setTimeout(() => logout(), 2000);
      } else {
        setMessage({ type: 'error', text: '保存に失敗しました' });
      }
    } finally {
      setLoading((prev) => ({ ...prev, saving: false }));
    }
  };

  const handleCancel = () => {
    if (profile) {
      setProfileForm({ name: profile.name });
    }
    setErrors({});
    setMessage(null);
  };

  if (loading.data) {
    return (
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">設定</h1>
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="text-center py-8 text-gray-600">読み込み中...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">設定</h1>

      {message && (
        <div className={`mb-4 p-3 rounded-lg ${
          message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
        }`}>
          {message.text}
        </div>
      )}

      <div className="bg-white rounded-lg shadow-md p-6 space-y-8">
        {/* プロフィール */}
        <div>
          <h2 className="text-lg font-bold text-gray-900 mb-4">プロフィール</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">お名前</label>
              <input
                type="text"
                value={profileForm.name}
                onChange={(e) => setProfileForm({ name: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              />
              {errors.name && (
                <p className="text-xs text-red-600 mt-1">{errors.name.join(', ')}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">メールアドレス</label>
              <input
                type="email"
                value={profile?.email || ''}
                disabled
                className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-gray-600"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">プロバイダー</label>
              <input
                type="text"
                value={profile?.provider === 'email' ? 'メール' : 'LINE'}
                disabled
                className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-gray-600"
              />
            </div>
          </div>
        </div>

        <div className="border-t border-gray-200 pt-6"></div>

        {/* 基本設定 */}
        <div>
          <h2 className="text-lg font-bold text-gray-900 mb-4">基本設定</h2>
          {settings && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">家族の人数</label>
                <input
                  type="number"
                  min="1"
                  max="10"
                  value={settings.default_servings}
                  onChange={(e) => setSettings({ ...settings, default_servings: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                />
                {errors.default_servings && (
                  <p className="text-xs text-red-600 mt-1">{errors.default_servings.join(', ')}</p>
                )}
                <p className="text-xs text-gray-500 mt-1">レシピの分量計算に使用されます</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">レシピの難易度</label>
                <select
                  value={settings.recipe_difficulty}
                  onChange={(e) => setSettings({ ...settings, recipe_difficulty: e.target.value as 'easy' | 'medium' | 'hard' })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                >
                  {DIFFICULTY_OPTIONS.map(option => (
                    <option key={option.value} value={option.value}>{option.label}</option>
                  ))}
                </select>
                {errors.recipe_difficulty && (
                  <p className="text-xs text-red-600 mt-1">{errors.recipe_difficulty.join(', ')}</p>
                )}
                <p className="text-xs text-gray-500 mt-1">あなたの料理スキルに合わせて調整</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">調理時間の目安</label>
                <select
                  value={settings.cooking_time}
                  onChange={(e) => setSettings({ ...settings, cooking_time: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                >
                  {COOKING_TIME_OPTIONS.map(option => (
                    <option key={option.value} value={option.value}>{option.label}</option>
                  ))}
                </select>
                {errors.cooking_time && (
                  <p className="text-xs text-red-600 mt-1">{errors.cooking_time.join(', ')}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">買い物の頻度</label>
                <select
                  value={settings.shopping_frequency}
                  onChange={(e) => setSettings({ ...settings, shopping_frequency: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                >
                  {SHOPPING_FREQUENCY_OPTIONS.map(option => (
                    <option key={option.value} value={option.value}>{option.label}</option>
                  ))}
                </select>
                {errors.shopping_frequency && (
                  <p className="text-xs text-red-600 mt-1">{errors.shopping_frequency.join(', ')}</p>
                )}
              </div>
            </div>
          )}
        </div>

        <div className="border-t border-gray-200 pt-6"></div>

        {/* LINE連携状態 */}
        <div>
          <h2 className="text-lg font-bold text-gray-900 mb-4">LINE連携</h2>
          <div className="p-4 bg-gray-50 rounded-lg">
            <div className="flex items-center gap-2">
              <div className="bg-green-500 text-white px-2 py-1 rounded text-sm font-bold">LINE</div>
              <span className="text-sm text-gray-600">
                {profile?.provider === 'line' ? '連携済み' : '未連携'}
              </span>
            </div>
          </div>
        </div>

        <div className="border-t border-gray-200 pt-6"></div>

        {/* パスワード・メールアドレス変更 */}
        <div>
          <h2 className="text-lg font-bold text-gray-900 mb-4">アカウント管理</h2>
          <p className="text-sm text-gray-600 mb-4">
            パスワードやメールアドレスの変更は、Web版の設定画面から行えます
          </p>
        </div>

        {/* 保存・キャンセルボタン */}
        <div className="flex gap-3 pt-4">
          <button
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700"
            onClick={handleCancel}
            disabled={loading.saving}
          >
            キャンセル
          </button>
          <button
            className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400"
            onClick={handleSave}
            disabled={loading.saving}
          >
            {loading.saving ? '保存中...' : '変更を保存'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default Settings;
