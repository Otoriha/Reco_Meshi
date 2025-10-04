import React, { useState, useEffect } from 'react';
import { FaUser, FaCog, FaClipboard } from 'react-icons/fa';
import { getUserProfile, getUserSettings, updateUserProfile, updateUserSettings } from '../../api/users';
import type { UserProfile, UserSettings } from '../../api/users';
import { DIFFICULTY_OPTIONS, COOKING_TIME_OPTIONS, SHOPPING_FREQUENCY_OPTIONS } from '../../constants/settings';
import { useToast } from '../../hooks/useToast';
import { useAuth } from '../../hooks/useAuth';

type SettingsTab = 'basic' | 'profile' | 'account';

const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState<SettingsTab>('basic');
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [profileForm, setProfileForm] = useState({ name: '' });
  const [loading, setLoading] = useState({ profile: true, settings: true, saving: false });
  const [errors, setErrors] = useState<{ [key: string]: string[] }>({});
  const { showToast } = useToast();
  const { logout } = useAuth();

  const menuItems = [
    { id: 'basic', label: '基本設定', icon: FaCog },
    { id: 'profile', label: 'プロフィール', icon: FaUser },
    { id: 'account', label: 'アカウント', icon: FaClipboard }
  ];

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
      } catch (error: any) {
        if (error.response?.status === 401) {
          showToast('セッションが切れました。再度ログインしてください', 'error');
          logout();
        } else {
          showToast('データの取得に失敗しました', 'error');
        }
      } finally {
        setLoading({ ...loading, profile: false, settings: false });
      }
    };

    fetchData();
  }, []);

  const handleProfileSave = async () => {
    setLoading({ ...loading, saving: true });
    setErrors({});
    try {
      const response = await updateUserProfile({ name: profileForm.name });
      showToast(response.message, 'success');
      setProfile({ ...profile!, name: profileForm.name });
    } catch (error: any) {
      if (error.response?.status === 422) {
        setErrors(error.response.data.errors);
        showToast('入力内容を確認してください', 'error');
      } else if (error.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('保存に失敗しました', 'error');
      }
    } finally {
      setLoading({ ...loading, saving: false });
    }
  };

  const handleSettingsSave = async () => {
    if (!settings) return;
    setLoading({ ...loading, saving: true });
    setErrors({});
    try {
      const response = await updateUserSettings(settings);
      showToast(response.message, 'success');
    } catch (error: any) {
      if (error.response?.status === 422) {
        setErrors(error.response.data.errors);
        showToast('入力内容を確認してください', 'error');
      } else if (error.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('保存に失敗しました', 'error');
      }
    } finally {
      setLoading({ ...loading, saving: false });
    }
  };

  const renderBasicSettings = () => (
    <div className="space-y-6">
      <h2 className="text-xl font-bold text-gray-900 mb-4">基本設定</h2>
      <p className="text-gray-600 mb-6">レシピの提案精度を高めます</p>

      {loading.settings ? (
        <div className="text-center py-8">読み込み中...</div>
      ) : settings && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
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
  );

  const renderProfile = () => (
    <div className="space-y-6">
      <h2 className="text-xl font-bold text-gray-900 mb-4">プロフィール</h2>

      {loading.profile ? (
        <div className="text-center py-8">読み込み中...</div>
      ) : profile && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
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
              value={profile.email}
              disabled
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-gray-600 cursor-not-allowed"
            />
            <p className="text-xs text-gray-500 mt-1">メールアドレスはアカウントタブから変更できます</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">プロバイダー</label>
            <input
              type="text"
              value={profile.provider === 'email' ? 'メール' : 'LINE'}
              disabled
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-gray-600 cursor-not-allowed"
            />
          </div>
        </div>
      )}
    </div>
  );

  const renderAccount = () => (
    <div className="space-y-6">
      <h2 className="text-xl font-bold text-gray-900 mb-4">アカウント</h2>

      <div className="space-y-4">
        <div className="p-4 bg-gray-50 rounded-lg">
          <h3 className="font-medium text-gray-900 mb-2">LINE連携</h3>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="bg-green-500 text-white px-2 py-1 rounded text-sm font-bold">LINE</div>
              <span className="text-sm text-gray-600">
                {profile?.provider === 'line' ? '連携済み' : '未連携'}
              </span>
            </div>
          </div>
        </div>

        <div className="flex gap-4">
          <button
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700"
            disabled
          >
            パスワード変更
          </button>
          <button
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700"
            disabled
          >
            メールアドレス変更
          </button>
          <button
            className="px-4 py-2 border border-red-300 text-red-600 rounded-lg hover:bg-red-50"
            disabled
          >
            アカウント削除
          </button>
        </div>
        <p className="text-xs text-gray-500 text-center">パスワード・メール変更機能は準備中です</p>
      </div>
    </div>
  );

  const renderContent = () => {
    switch (activeTab) {
      case 'basic':
        return renderBasicSettings();
      case 'profile':
        return renderProfile();
      case 'account':
        return renderAccount();
      default:
        return renderBasicSettings();
    }
  };

  const handleSave = () => {
    if (activeTab === 'profile') {
      handleProfileSave();
    } else if (activeTab === 'basic') {
      handleSettingsSave();
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex">
          <div className="w-64 bg-white rounded-lg shadow-sm p-4 mr-6 h-fit">
            <h1 className="text-lg font-bold text-gray-900 mb-4">設定</h1>
            <nav className="space-y-2">
              {menuItems.map((item) => {
                const Icon = item.icon;
                return (
                  <button
                    key={item.id}
                    onClick={() => setActiveTab(item.id as SettingsTab)}
                    className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left transition-colors ${
                      activeTab === item.id
                        ? 'bg-green-100 text-green-800 font-medium'
                        : 'text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    {item.label}
                  </button>
                );
              })}
            </nav>
          </div>

          <div className="flex-1">
            <div className="bg-white rounded-lg shadow-sm p-6">
              {renderContent()}

              {activeTab !== 'account' && (
                <div className="flex justify-end gap-4 mt-8 pt-6 border-t border-gray-200">
                  <button
                    className="px-6 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700"
                    onClick={() => {
                      if (activeTab === 'profile' && profile) {
                        setProfileForm({ name: profile.name });
                      }
                      setErrors({});
                    }}
                    disabled={loading.saving}
                  >
                    キャンセル
                  </button>
                  <button
                    className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400"
                    onClick={handleSave}
                    disabled={loading.saving}
                  >
                    {loading.saving ? '保存中...' : '変更を保存'}
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
