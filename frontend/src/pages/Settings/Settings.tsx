import React, { useState, useEffect } from 'react';
import { FaUser, FaCog, FaClipboard, FaExclamationTriangle, FaBan, FaShieldAlt } from 'react-icons/fa';
import { getUserProfile, getUserSettings, updateUserProfile, updateUserSettings } from '../../api/users';
import type { UserProfile, UserSettings } from '../../api/users';
import { DIFFICULTY_OPTIONS, COOKING_TIME_OPTIONS, SHOPPING_FREQUENCY_OPTIONS } from '../../constants/settings';
import { useToast } from '../../hooks/useToast';
import { useAuth } from '../../hooks/useAuth';
import { useAnalytics } from '../../hooks/useAnalytics';
import { getAllergyIngredients, createAllergyIngredient, updateAllergyIngredient, deleteAllergyIngredient } from '../../api/allergyIngredients';
import type { AllergyIngredient } from '../../types/allergy';
import { getDislikedIngredients, createDislikedIngredient, updateDislikedIngredient, deleteDislikedIngredient } from '../../api/dislikedIngredients';
import type { DislikedIngredient } from '../../types/disliked';
import AddAllergyModal from '../../components/settings/AddAllergyModal';
import EditAllergyModal from '../../components/settings/EditAllergyModal';
import AddDislikedModal from '../../components/settings/AddDislikedModal';
import EditDislikedModal from '../../components/settings/EditDislikedModal';
import { generateLineNonce } from '../../api/auth';
import { generateState } from '../../utils/crypto';

type SettingsTab = 'basic' | 'profile' | 'account' | 'allergy' | 'disliked' | 'cookie';

const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState<SettingsTab>('basic');
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [allergies, setAllergies] = useState<AllergyIngredient[]>([]);
  const [dislikedIngredients, setDislikedIngredients] = useState<DislikedIngredient[]>([]);
  const [profileForm, setProfileForm] = useState({ name: '' });
  const [loading, setLoading] = useState({ profile: true, settings: true, allergies: true, disliked: true, saving: false, lineLinking: false });
  const [errors, setErrors] = useState<{ [key: string]: string[] }>({});
  const [error, setError] = useState('');
  const [isAddAllergyOpen, setIsAddAllergyOpen] = useState(false);
  const [editingAllergy, setEditingAllergy] = useState<AllergyIngredient | null>(null);
  const [isAddDislikedOpen, setIsAddDislikedOpen] = useState(false);
  const [editingDisliked, setEditingDisliked] = useState<DislikedIngredient | null>(null);
  const { showToast } = useToast();
  const { logout } = useAuth();
  const { consentStatus, updateConsent } = useAnalytics();

  const menuItems = [
    { id: 'basic', label: '基本設定', icon: FaCog },
    { id: 'profile', label: 'プロフィール', icon: FaUser },
    { id: 'allergy', label: 'アレルギー食材', icon: FaExclamationTriangle },
    { id: 'disliked', label: '苦手な食材', icon: FaBan },
    { id: 'cookie', label: 'クッキー設定', icon: FaShieldAlt },
    { id: 'account', label: 'アカウント', icon: FaClipboard }
  ];

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [profileData, settingsData, allergiesData, dislikedData] = await Promise.all([
          getUserProfile(),
          getUserSettings(),
          getAllergyIngredients(),
          getDislikedIngredients()
        ]);
        setProfile(profileData);
        setSettings(settingsData);
        setAllergies(allergiesData);
        setDislikedIngredients(dislikedData);
        setProfileForm({ name: profileData.name });
      } catch (error) {
        const err = error as { response?: { status?: number } };
        if (err.response?.status === 401) {
          showToast('セッションが切れました。再度ログインしてください', 'error');
          logout();
        } else {
          showToast('データの取得に失敗しました', 'error');
        }
      } finally {
        setLoading((prev) => ({ ...prev, profile: false, settings: false, allergies: false, disliked: false }));
      }
    };

    fetchData();
  }, [logout, showToast]);

  const handleProfileSave = async () => {
    setLoading((prev) => ({ ...prev, saving: true }));
    setErrors({});
    try {
      const response = await updateUserProfile({ name: profileForm.name });
      showToast(response.message, 'success');
      setProfile({ ...profile!, name: profileForm.name });
    } catch (error) {
      const err = error as { response?: { status?: number; data?: { errors?: Record<string, string[]> } } };
      if (err.response?.status === 422) {
        setErrors(err.response.data?.errors || {});
        showToast('入力内容を確認してください', 'error');
      } else if (err.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('保存に失敗しました', 'error');
      }
    } finally {
      setLoading((prev) => ({ ...prev, saving: false }));
    }
  };

  const handleSettingsSave = async () => {
    if (!settings) return;
    setLoading((prev) => ({ ...prev, saving: true }));
    setErrors({});
    try {
      const response = await updateUserSettings(settings);
      showToast(response.message, 'success');
    } catch (error) {
      const err = error as { response?: { status?: number; data?: { errors?: Record<string, string[]> } } };
      if (err.response?.status === 422) {
        setErrors(err.response.data?.errors || {});
        showToast('入力内容を確認してください', 'error');
      } else if (err.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('保存に失敗しました', 'error');
      }
    } finally {
      setLoading((prev) => ({ ...prev, saving: false }));
    }
  };

  const handleAddAllergy = async (data: { ingredient_id: number; note?: string }) => {
    try {
      const newAllergy = await createAllergyIngredient(data);
      setAllergies([...allergies, newAllergy]);
      showToast('アレルギー食材を追加しました', 'success');
    } catch (error) {
      const err = error as { response?: { status?: number } };
      if (err.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('追加に失敗しました', 'error');
      }
      throw error;
    }
  };

  const handleUpdateAllergy = async (data: { note?: string }) => {
    if (!editingAllergy) return;
    try {
      const updatedAllergy = await updateAllergyIngredient(editingAllergy.id, data);
      setAllergies(allergies.map(a => a.id === updatedAllergy.id ? updatedAllergy : a));
      setEditingAllergy(null);
      showToast('アレルギー食材を更新しました', 'success');
    } catch (error) {
      const err = error as { response?: { status?: number } };
      if (err.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('更新に失敗しました', 'error');
      }
      throw error;
    }
  };

  const handleDeleteAllergy = async (id: number) => {
    if (!confirm('このアレルギー食材を削除しますか？')) return;
    try {
      await deleteAllergyIngredient(id);
      setAllergies(allergies.filter(a => a.id !== id));
      showToast('アレルギー食材を削除しました', 'success');
    } catch (error) {
      const err = error as { response?: { status?: number } };
      if (err.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('削除に失敗しました', 'error');
      }
    }
  };

  const handleAddDisliked = async (data: { ingredient_id: number; priority: 'low' | 'medium' | 'high'; reason?: string }) => {
    try {
      const newDisliked = await createDislikedIngredient(data);
      setDislikedIngredients([...dislikedIngredients, newDisliked]);
      showToast('苦手な食材を追加しました', 'success');
    } catch (error) {
      const err = error as { response?: { status?: number } };
      if (err.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('追加に失敗しました', 'error');
      }
      throw error;
    }
  };

  const handleUpdateDisliked = async (data: { priority?: 'low' | 'medium' | 'high'; reason?: string }) => {
    if (!editingDisliked) return;
    try {
      const updatedDisliked = await updateDislikedIngredient(Number(editingDisliked.id), data);
      setDislikedIngredients(dislikedIngredients.map(d => d.id === updatedDisliked.id ? updatedDisliked : d));
      setEditingDisliked(null);
      showToast('苦手な食材を更新しました', 'success');
    } catch (error) {
      const err = error as { response?: { status?: number } };
      if (err.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('更新に失敗しました', 'error');
      }
      throw error;
    }
  };

  const handleDeleteDisliked = async (id: string) => {
    if (!confirm('この苦手な食材を削除しますか？')) return;
    try {
      await deleteDislikedIngredient(Number(id));
      setDislikedIngredients(dislikedIngredients.filter(d => d.id !== id));
      showToast('苦手な食材を削除しました', 'success');
    } catch (error) {
      const err = error as { response?: { status?: number } };
      if (err.response?.status === 401) {
        showToast('セッションが切れました。再度ログインしてください', 'error');
        logout();
      } else {
        showToast('削除に失敗しました', 'error');
      }
    }
  };

  const handleLineLink = async () => {
    try {
      setLoading((prev) => ({ ...prev, lineLinking: true }));
      setError('');

      // 1. バックエンドからノンスを取得
      const nonce = await generateLineNonce();

      // 2. stateを生成
      const state = generateState();

      // 3. sessionStorageに保存（通常ログインと区別するため異なるキー名）
      sessionStorage.setItem('line_link_nonce', nonce);
      sessionStorage.setItem('line_link_state', state);

      // 4. LINE認証ページへリダイレクト
      const params = new URLSearchParams({
        response_type: 'code',
        client_id: import.meta.env.VITE_LINE_CHANNEL_ID,
        redirect_uri: import.meta.env.VITE_LINE_LOGIN_CALLBACK_URL,
        state: state,
        scope: 'openid profile email',
        nonce: nonce
      });

      window.location.href = `https://access.line.me/oauth2/v2.1/authorize?${params}`;
    } catch (err) {
      console.error('LINE link preparation failed:', err);
      setError('LINE連携の準備に失敗しました');
      showToast('LINE連携の準備に失敗しました', 'error');
      setLoading((prev) => ({ ...prev, lineLinking: false }));
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

  const renderAllergyIngredients = () => {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold text-gray-900">アレルギー食材</h2>
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            onClick={() => setIsAddAllergyOpen(true)}
          >
            新規登録
          </button>
        </div>

        {loading.allergies ? (
          <div className="text-center py-8">読み込み中...</div>
        ) : allergies.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            アレルギー食材が登録されていません
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">食材名</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">備考</th>
                  <th className="px-4 py-3 text-right text-sm font-medium text-gray-700">操作</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {allergies.map((allergy) => (
                  <tr key={allergy.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm text-gray-900">
                      {allergy.ingredient.name}
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      {allergy.note ? (
                        allergy.note.length > 50 ? `${allergy.note.substring(0, 50)}...` : allergy.note
                      ) : (
                        <span className="text-gray-400">-</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        className="text-blue-600 hover:text-blue-800 text-sm mr-3"
                        onClick={() => setEditingAllergy(allergy)}
                      >
                        編集
                      </button>
                      <button
                        className="text-red-600 hover:text-red-800 text-sm"
                        onClick={() => handleDeleteAllergy(allergy.id)}
                      >
                        削除
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    );
  };

  const renderDislikedIngredients = () => {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold text-gray-900">苦手な食材</h2>
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            onClick={() => setIsAddDislikedOpen(true)}
          >
            新規登録
          </button>
        </div>

        {loading.disliked ? (
          <div className="text-center py-8">読み込み中...</div>
        ) : dislikedIngredients.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            苦手な食材が登録されていません
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">食材名</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">優先度</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">理由</th>
                  <th className="px-4 py-3 text-right text-sm font-medium text-gray-700">操作</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {dislikedIngredients.map((disliked) => (
                  <tr key={disliked.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm text-gray-900">
                      {disliked.ingredient.name}
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-900">
                      {disliked.priority_label}
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      {disliked.reason ? (
                        disliked.reason.length > 50 ? `${disliked.reason.substring(0, 50)}...` : disliked.reason
                      ) : (
                        <span className="text-gray-400">-</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        className="text-blue-600 hover:text-blue-800 text-sm mr-3"
                        onClick={() => setEditingDisliked(disliked)}
                      >
                        編集
                      </button>
                      <button
                        className="text-red-600 hover:text-red-800 text-sm"
                        onClick={() => handleDeleteDisliked(disliked.id)}
                      >
                        削除
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    );
  };

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
                {profile?.provider === 'line' || profile?.lineAccount ? '連携済み' : '未連携'}
              </span>
            </div>
            {profile?.provider !== 'line' && !profile?.lineAccount && (
              <button
                className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 disabled:bg-gray-400"
                onClick={handleLineLink}
                disabled={loading.lineLinking}
              >
                {loading.lineLinking ? '処理中...' : 'LINEと連携'}
              </button>
            )}
          </div>
          {(profile?.provider === 'line' || profile?.lineAccount) && (
            <div className="mt-2 text-sm text-gray-600">
              <p>表示名: {profile?.lineAccount?.displayName || 'N/A'}</p>
              <p>連携日時: {profile?.lineAccount?.linkedAt ? new Date(profile.lineAccount.linkedAt).toLocaleString('ja-JP') : 'N/A'}</p>
            </div>
          )}
          {error && (
            <p className="mt-2 text-sm text-red-600">{error}</p>
          )}
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

  const renderCookieSettings = () => {
    const handleGrantConsent = () => {
      updateConsent('granted');
      showToast('クッキーの使用に同意しました', 'success');
    };

    const handleRevokeConsent = () => {
      if (confirm('クッキーの使用を拒否しますか？アクセス解析が無効になります。')) {
        updateConsent('denied');
        showToast('クッキーの使用を拒否しました', 'success');
      }
    };

    return (
      <div className="space-y-6">
        <h2 className="text-xl font-bold text-gray-900 mb-4">クッキー設定</h2>

        <div className="p-4 bg-gray-50 rounded-lg">
          <h3 className="font-medium text-gray-900 mb-2">アクセス解析Cookie</h3>
          <div className="mb-4">
            <p className="text-sm text-gray-600 mb-2">
              現在のステータス:
              <span className={`ml-2 font-medium ${
                consentStatus === 'granted' ? 'text-green-600' :
                consentStatus === 'denied' ? 'text-red-600' :
                'text-gray-600'
              }`}>
                {consentStatus === 'granted' && '同意済み'}
                {consentStatus === 'denied' && '拒否済み'}
                {consentStatus === 'pending' && '未設定'}
              </span>
            </p>
            <p className="text-sm text-gray-600 mb-4">
              当サービスでは、サービス改善のためにGoogle Analytics 4を使用してアクセス解析を行っています。
              収集されたデータは匿名化され、統計的な分析にのみ使用されます。
            </p>
          </div>

          <div className="flex gap-2">
            {consentStatus !== 'granted' && (
              <button
                onClick={handleGrantConsent}
                className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition-colors"
              >
                同意する
              </button>
            )}
            {consentStatus === 'granted' && (
              <button
                onClick={handleRevokeConsent}
                className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
              >
                同意を撤回する
              </button>
            )}
          </div>

          <div className="mt-4 p-3 bg-blue-50 rounded">
            <p className="text-xs text-gray-700">
              詳細については
              <a href="/privacy" className="text-blue-600 hover:underline ml-1">
                プライバシーポリシー
              </a>
              をご確認ください。
            </p>
          </div>
        </div>
      </div>
    );
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'basic':
        return renderBasicSettings();
      case 'profile':
        return renderProfile();
      case 'allergy':
        return renderAllergyIngredients();
      case 'disliked':
        return renderDislikedIngredients();
      case 'cookie':
        return renderCookieSettings();
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

              {activeTab !== 'account' && activeTab !== 'allergy' && activeTab !== 'disliked' && activeTab !== 'cookie' && (
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

        {/* モーダル */}
        <AddAllergyModal
          isOpen={isAddAllergyOpen}
          onClose={() => setIsAddAllergyOpen(false)}
          onSubmit={handleAddAllergy}
          existingAllergies={allergies}
        />
        <EditAllergyModal
          isOpen={!!editingAllergy}
          onClose={() => setEditingAllergy(null)}
          onSubmit={handleUpdateAllergy}
          allergy={editingAllergy}
        />
        <AddDislikedModal
          isOpen={isAddDislikedOpen}
          onClose={() => setIsAddDislikedOpen(false)}
          onSubmit={handleAddDisliked}
          existingDisliked={dislikedIngredients}
        />
        <EditDislikedModal
          isOpen={!!editingDisliked}
          onClose={() => setEditingDisliked(null)}
          onSubmit={handleUpdateDisliked}
          disliked={editingDisliked}
        />
      </div>
    </div>
  );
};

export default Settings;
