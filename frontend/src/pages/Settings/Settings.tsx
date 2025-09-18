import React, { useState } from 'react';
import { FaUser, FaCog, FaBell, FaExclamationTriangle, FaClipboard, FaUserCircle } from 'react-icons/fa';

type SettingsTab = 'basic' | 'profile' | 'allergies' | 'notifications' | 'account';

const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState<SettingsTab>('basic');
  const [formData, setFormData] = useState({
    familySize: '3人',
    recipeDifficulty: '簡単なレシピ中心',
    cookingTime: '30分以内',
    shoppingFrequency: '2-3日に1回',
    name: '山田太郎',
    nickname: 'やまだ',
    email: 'yamada.taro@example.com',
    allergies: ['卵', 'えび', '小麦'],
    dislikes: ['ピーマン', 'セロリ'],
    recipeNotifications: true,
    stockReminder: true,
    foodWasteAlert: false
  });

  const [showAllergyInput, setShowAllergyInput] = useState(false);
  const [showDislikeInput, setShowDislikeInput] = useState(false);

  const menuItems = [
    { id: 'basic', label: '基本設定', icon: FaCog },
    { id: 'profile', label: 'プロフィール', icon: FaUser },
    { id: 'allergies', label: 'アレルギー・苦手', icon: FaExclamationTriangle },
    { id: 'notifications', label: '通知設定', icon: FaBell },
    { id: 'account', label: 'アカウント', icon: FaClipboard }
  ];

  const handleToggle = (field: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: !prev[field as keyof typeof prev]
    }));
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const addItem = (field: 'allergies' | 'dislikes', item: string) => {
    if (item.trim()) {
      setFormData(prev => ({
        ...prev,
        [field]: [...prev[field], item.trim()]
      }));
    }
  };

  const removeItem = (field: 'allergies' | 'dislikes', index: number) => {
    setFormData(prev => ({
      ...prev,
      [field]: prev[field].filter((_, i) => i !== index)
    }));
  };

  const renderBasicSettings = () => (
    <div className="space-y-6">
      <h2 className="text-xl font-bold text-gray-900 mb-4">基本設定</h2>
      <p className="text-gray-600 mb-6">レシピの提案精度を高めます</p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">家族の人数</label>
          <select
            value={formData.familySize}
            onChange={(e) => handleInputChange('familySize', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
          >
            <option value="1人">1人</option>
            <option value="2人">2人</option>
            <option value="3人">3人</option>
            <option value="4人">4人</option>
            <option value="5人以上">5人以上</option>
          </select>
          <p className="text-xs text-gray-500 mt-1">レシピの分量計算に使用されます</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">レシピの難易度</label>
          <select
            value={formData.recipeDifficulty}
            onChange={(e) => handleInputChange('recipeDifficulty', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
          >
            <option value="簡単なレシピ中心">簡単なレシピ中心</option>
            <option value="本格的なレシピ">本格的なレシピ</option>
            <option value="バランス重視">バランス重視</option>
          </select>
          <p className="text-xs text-gray-500 mt-1">あなたの料理スキルに合わせて調整</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">調理時間の目安</label>
          <select
            value={formData.cookingTime}
            onChange={(e) => handleInputChange('cookingTime', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
          >
            <option value="15分以内">15分以内</option>
            <option value="30分以内">30分以内</option>
            <option value="1時間以内">1時間以内</option>
            <option value="時間制限なし">時間制限なし</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">買い物の頻度</label>
          <select
            value={formData.shoppingFrequency}
            onChange={(e) => handleInputChange('shoppingFrequency', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
          >
            <option value="毎日">毎日</option>
            <option value="2-3日に1回">2-3日に1回</option>
            <option value="週に1回">週に1回</option>
            <option value="まとめ買い">まとめ買い</option>
          </select>
        </div>
      </div>
    </div>
  );

  const renderProfile = () => (
    <div className="space-y-6">
      <h2 className="text-xl font-bold text-gray-900 mb-4">プロフィール</h2>

      <div className="flex items-center space-x-4 mb-6">
        <div className="w-20 h-20 bg-gray-200 rounded-full flex items-center justify-center">
          <FaUserCircle className="w-16 h-16 text-gray-400" />
        </div>
        <div>
          <p className="text-sm text-gray-600">プロフィール画像を変更</p>
          <p className="text-xs text-gray-500">画像を追加</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">お名前</label>
          <input
            type="text"
            value={formData.name}
            onChange={(e) => handleInputChange('name', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">ニックネーム</label>
          <input
            type="text"
            value={formData.nickname}
            onChange={(e) => handleInputChange('nickname', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
            placeholder="やまだ"
          />
          <p className="text-xs text-gray-500 mt-1">画面で表示される名前です</p>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">メールアドレス</label>
        <input
          type="email"
          value={formData.email}
          onChange={(e) => handleInputChange('email', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
        />
        <p className="text-xs text-gray-500 mt-1">アカウント情報や通知を送信します</p>
      </div>
    </div>
  );

  const renderAllergiesSection = () => (
    <div className="space-y-6">
      <h2 className="text-xl font-bold text-gray-900 mb-4">アレルギー・苦手な食材</h2>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <div className="flex items-center justify-between mb-3">
            <label className="block text-sm font-medium text-gray-700">アレルギー食材</label>
            <button
              onClick={() => setShowAllergyInput(!showAllergyInput)}
              className="bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700"
            >
              + 追加
            </button>
          </div>
          <div className="flex flex-wrap gap-2 mb-3">
            {formData.allergies.map((allergy, index) => (
              <span
                key={index}
                className="bg-red-100 text-red-800 px-3 py-1 rounded-full text-sm flex items-center gap-2"
              >
                {allergy}
                <button
                  onClick={() => removeItem('allergies', index)}
                  className="text-red-600 hover:text-red-800"
                >
                  ×
                </button>
              </span>
            ))}
          </div>
          {showAllergyInput && (
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="アレルギー食材を入力"
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md"
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    addItem('allergies', e.currentTarget.value);
                    e.currentTarget.value = '';
                  }
                }}
              />
            </div>
          )}
        </div>

        <div>
          <div className="flex items-center justify-between mb-3">
            <label className="block text-sm font-medium text-gray-700">苦手な食材</label>
            <button
              onClick={() => setShowDislikeInput(!showDislikeInput)}
              className="bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700"
            >
              + 追加
            </button>
          </div>
          <div className="flex flex-wrap gap-2 mb-3">
            {formData.dislikes.map((dislike, index) => (
              <span
                key={index}
                className="bg-orange-100 text-orange-800 px-3 py-1 rounded-full text-sm flex items-center gap-2"
              >
                {dislike}
                <button
                  onClick={() => removeItem('dislikes', index)}
                  className="text-orange-600 hover:text-orange-800"
                >
                  ×
                </button>
              </span>
            ))}
          </div>
          {showDislikeInput && (
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="苦手な食材を入力"
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md"
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    addItem('dislikes', e.currentTarget.value);
                    e.currentTarget.value = '';
                  }
                }}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );

  const renderNotifications = () => (
    <div className="space-y-6">
      <h2 className="text-xl font-bold text-gray-900 mb-4">通知設定</h2>

      <div className="space-y-4">
        <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
          <div>
            <h3 className="font-medium text-gray-900">レシピ提案通知</h3>
            <p className="text-sm text-gray-600">毎日午後5時にレシピを提案します</p>
            <div className="mt-2">
              <select className="text-sm border border-gray-300 rounded px-2 py-1">
                <option>17:00</option>
                <option>18:00</option>
                <option>19:00</option>
              </select>
              <span className="ml-2 text-sm text-gray-600">に通知</span>
            </div>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={formData.recipeNotifications}
              onChange={() => handleToggle('recipeNotifications')}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
          </label>
        </div>

        <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
          <div>
            <h3 className="font-medium text-gray-900">在庫確認リマインダー</h3>
            <p className="text-sm text-gray-600">定期的に食材の在庫確認を促します</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={formData.stockReminder}
              onChange={() => handleToggle('stockReminder')}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
          </label>
        </div>

        <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
          <div>
            <h3 className="font-medium text-gray-900">食材廃棄アラート</h3>
            <p className="text-sm text-gray-600">消費期限が近い食材をお知らせします</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={formData.foodWasteAlert}
              onChange={() => handleToggle('foodWasteAlert')}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
          </label>
        </div>
      </div>
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
              <span className="text-sm text-gray-600">連携済み</span>
            </div>
            <button className="text-sm text-gray-600 hover:text-gray-800">連携解除</button>
          </div>
        </div>

        <div className="flex gap-4">
          <button className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700">
            パスワード変更
          </button>
          <button className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700">
            メールアドレス変更
          </button>
          <button className="px-4 py-2 border border-red-300 text-red-600 rounded-lg hover:bg-red-50">
            アカウント削除
          </button>
        </div>
      </div>
    </div>
  );

  const renderContent = () => {
    switch (activeTab) {
      case 'basic':
        return renderBasicSettings();
      case 'profile':
        return renderProfile();
      case 'allergies':
        return renderAllergiesSection();
      case 'notifications':
        return renderNotifications();
      case 'account':
        return renderAccount();
      default:
        return renderBasicSettings();
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex">
          {/* 左サイドバー */}
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

          {/* メインコンテンツ */}
          <div className="flex-1">
            <div className="bg-white rounded-lg shadow-sm p-6">
              {renderContent()}

              {/* 保存ボタン */}
              <div className="flex justify-end gap-4 mt-8 pt-6 border-t border-gray-200">
                <button className="px-6 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700">
                  キャンセル
                </button>
                <button className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
                  変更を保存
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;