import React from 'react';
import { Link } from 'react-router-dom';
import { FaLine, FaSearch, FaShoppingCart } from 'react-icons/fa';
import { HiDesktopComputer, HiCamera, HiChartBar } from 'react-icons/hi';

const FeaturesSection: React.FC = () => {
  return (
    <section className="py-16 sm:py-24 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* セクションタイトル */}
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">
            あなたに合った使い方を選べます
          </h2>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            ライフスタイルに合わせて、お気に入りのプラットフォームで食材管理ができます。
          </p>
        </div>

        {/* LINE版とWEB版の比較 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-24">
          {/* LINE版 */}
          <div className="bg-green-50 rounded-2xl p-8 border-2 border-green-200">
            <div className="flex items-center space-x-3 mb-6">
              <FaLine className="text-3xl text-green-500" />
              <h3 className="text-2xl font-bold text-gray-900">LINE版</h3>
            </div>
            <p className="text-gray-600 mb-6">
              いつものLINEで手軽に食材管理。写真を送るだけでかんたんスタート。
            </p>

            <ul className="space-y-3 mb-8">
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">写真認識</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">食材リストの確認と編集</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">レシピ提案</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">買い物リスト作成</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">基本的な設定</span>
              </li>
            </ul>

            <button className="w-full bg-green-500 text-white py-3 px-6 rounded-lg hover:bg-green-600 transition-colors font-medium">
              LINEで今すぐ始める
            </button>
          </div>

          {/* WEB版 */}
          <div className="bg-gray-50 rounded-2xl p-8 border-2 border-gray-200">
            <div className="flex items-center space-x-3 mb-6">
              <HiDesktopComputer className="text-3xl text-gray-700" />
              <h3 className="text-2xl font-bold text-gray-900">WEB版</h3>
            </div>
            <p className="text-gray-600 mb-6">
              ブラウザで本格的な食材管理。詳細な機能でより効率的に。
            </p>

            <ul className="space-y-3 mb-8">
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-700 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">写真認識機能</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-700 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">詳細な在庫管理</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-700 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">レシピ履歴管理</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-700 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">お気に入りレシピ</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-700 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">高度な設定・統計</span>
              </li>
            </ul>

            <Link
              to="/signup"
              className="block w-full bg-gray-700 text-white py-3 px-6 rounded-lg hover:bg-gray-800 transition-colors font-medium text-center"
            >
              無料で始める
            </Link>
          </div>
        </div>

        {/* 3つの特徴 */}
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">
            レコめしの特徴
          </h2>
          <p className="text-lg text-gray-600">
            毎日の食材管理をもっと楽しく、もっと効率的に
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* 写真で簡単認識 */}
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-6">
              <HiCamera className="text-3xl text-blue-600" />
            </div>
            <h3 className="text-xl font-bold text-gray-900 mb-4">写真で簡単認識</h3>
            <p className="text-gray-600">
              冷蔵庫の写真を撮るだけで、AI が食材を自動認識。手入力の手間を大幅削減します。
            </p>
          </div>

          {/* 最適レシピ提案 */}
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-orange-100 rounded-full mb-6">
              <FaSearch className="text-3xl text-orange-600" />
            </div>
            <h3 className="text-xl font-bold text-gray-900 mb-4">最適レシピ提案</h3>
            <p className="text-gray-600">
              今ある食材から作れるレシピを AI が提案。食材を無駄にすることなく美味しい料理を。
            </p>
          </div>

          {/* 買い物管理 */}
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-6">
              <FaShoppingCart className="text-3xl text-green-600" />
            </div>
            <h3 className="text-xl font-bold text-gray-900 mb-4">買い物管理</h3>
            <p className="text-gray-600">
              不足している食材を自動でリストアップ。計画的な買い物で食材の無駄を防ぎます。
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default FeaturesSection;