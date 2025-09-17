import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { FaCamera, FaClipboardList, FaHistory, FaCog } from 'react-icons/fa';
import { HiSparkles } from 'react-icons/hi';

const Dashboard: React.FC = () => {
  const { user } = useAuth();

  const today = new Date();
  const formattedDate = `${today.getFullYear()}年${today.getMonth() + 1}月${today.getDate()}日 (${['日', '月', '火', '水', '木', '金', '土'][today.getDay()]})`;

  const handleImageUpload = () => {
    // TODO: 画像アップロード機能の実装
    console.log('画像アップロード機能');
  };

  const handleRecipeSuggest = () => {
    // TODO: レシピ提案機能の実装
    console.log('レシピ提案機能');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* 挨拶セクション */}
        <div className="mb-8">
          <div className="flex justify-between items-center mb-4">
            <h1 className="text-3xl font-bold text-gray-900">
              ようこそ、{user?.name || 'ユーザー'}さん！
            </h1>
            <p className="text-gray-600">{formattedDate}</p>
          </div>
          <div className="space-y-2">
            <p className="text-gray-700">今日も食材を無駄なく使い切りましょう。</p>
            <p className="text-gray-700">冷蔵庫の写真を撮って、今日のレシピを見つけてください。</p>
          </div>
        </div>

        {/* メインアクションカード */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* 冷蔵庫の写真を撮影 */}
          <div className="bg-white rounded-lg shadow-sm border-2 border-dashed border-green-300 p-8 hover:border-green-400 transition-colors">
            <div className="text-center">
              <div className="mb-4">
                <FaCamera className="mx-auto h-12 w-12 text-green-500" />
              </div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">冷蔵庫の写真を撮影</h2>
              <p className="text-gray-600 mb-2">冷蔵庫の中身が見えるように写真を撮ってください。</p>
              <p className="text-gray-600 mb-6">複数枚の写真をアップロードすることもできます。</p>

              <div className="space-y-4">
                <div className="text-gray-500 text-sm">
                  <p>写真をドラッグ&ドロップ</p>
                  <p>または</p>
                </div>
                <button
                  onClick={handleImageUpload}
                  className="bg-green-600 text-white px-6 py-3 rounded-md hover:bg-green-700 transition-colors font-medium"
                >
                  写真を選択
                </button>
              </div>
            </div>
          </div>

          {/* レシピを提案してもらう */}
          <div className="bg-white rounded-lg shadow-sm border-2 border-dashed border-pink-300 p-8 hover:border-pink-400 transition-colors">
            <div className="text-center">
              <div className="mb-4">
                <HiSparkles className="mx-auto h-12 w-12 text-pink-500" />
              </div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">レシピを提案してもらう</h2>
              <p className="text-gray-600 mb-2">今ある食材を伝えるだけで</p>
              <p className="text-gray-600 mb-6">AIが最適なレシピを提案します。</p>

              <div className="space-y-4">
                <div className="text-gray-700 font-medium">
                  <p>AIにレシピ提案を任せる</p>
                  <p className="text-sm text-gray-500">食材から自動でレシピを生成</p>
                </div>
                <button
                  onClick={handleRecipeSuggest}
                  className="bg-pink-500 text-white px-6 py-3 rounded-md hover:bg-pink-600 transition-colors font-medium"
                >
                  レシピ提案を依頼する
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* 機能紹介セクション */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Link to="/ingredients" className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow">
            <div className="text-center">
              <FaClipboardList className="mx-auto h-8 w-8 text-gray-600 mb-4" />
              <h3 className="text-lg font-bold text-gray-900 mb-2">在庫リスト</h3>
              <p className="text-gray-600 text-sm">現在の食材在庫を確認・編集できます</p>
            </div>
          </Link>

          <Link to="/recipe-history" className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow">
            <div className="text-center">
              <FaHistory className="mx-auto h-8 w-8 text-gray-600 mb-4" />
              <h3 className="text-lg font-bold text-gray-900 mb-2">レシピ履歴</h3>
              <p className="text-gray-600 text-sm">過去に作ったレシピを確認できます</p>
            </div>
          </Link>

          <Link to="/settings" className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow">
            <div className="text-center">
              <FaCog className="mx-auto h-8 w-8 text-gray-600 mb-4" />
              <h3 className="text-lg font-bold text-gray-900 mb-2">設定</h3>
              <p className="text-gray-600 text-sm">プロフィールや通知設定を管理できます</p>
            </div>
          </Link>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;