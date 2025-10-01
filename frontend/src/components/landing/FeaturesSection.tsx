import React from 'react';
import { Link } from 'react-router-dom';
import { FaLine, FaSearch, FaShoppingCart } from 'react-icons/fa';
import { HiDesktopComputer, HiCamera, HiChartBar } from 'react-icons/hi';

const FeaturesSection: React.FC = () => {
  return (
    <section className="py-12 sm:py-16 bg-white">
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
          <div className="bg-gray-50 rounded-2xl p-8 border-2 border-gray-200 relative opacity-75">
            <div className="absolute top-4 right-4 bg-gray-500 text-white text-xs px-3 py-1 rounded-full font-medium">
              準備中
            </div>
            <div className="flex items-center space-x-3 mb-6">
              <FaLine className="text-3xl text-gray-500" />
              <h3 className="text-2xl font-bold text-gray-600">LINE版</h3>
            </div>
            <p className="text-gray-500 mb-6">
              いつものLINEで手軽に食材管理。写真を送るだけでかんたんスタート。
            </p>

            <ul className="space-y-3 mb-8">
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-400 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-500">写真認識</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-400 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-500">食材リストの確認と編集</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-400 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-500">レシピ提案</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-400 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-500">買い物リスト作成</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-gray-400 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-500">基本的な設定</span>
              </li>
            </ul>

            <button
              disabled
              className="w-full bg-gray-400 text-gray-600 py-3 px-6 rounded-lg cursor-not-allowed font-medium"
            >
              近日公開予定
            </button>
          </div>

          {/* WEB版 */}
          <div className="bg-green-50 rounded-2xl p-8 border-2 border-green-200 relative">
            <div className="absolute top-4 right-4 bg-green-500 text-white text-xs px-3 py-1 rounded-full font-medium">
              おすすめ
            </div>
            <div className="flex items-center space-x-3 mb-6">
              <HiDesktopComputer className="text-3xl text-green-600" />
              <h3 className="text-2xl font-bold text-gray-900">WEB版</h3>
            </div>
            <p className="text-gray-600 mb-6">
              ブラウザで本格的な食材管理。詳細な機能でより効率的に。
            </p>

            <ul className="space-y-3 mb-8">
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">写真認識機能</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">詳細な在庫管理</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">レシピ履歴管理</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">お気に入りレシピ</span>
              </li>
              <li className="flex items-start space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2 flex-shrink-0"></div>
                <span className="text-gray-700">高度な設定・統計</span>
              </li>
            </ul>

            <Link
              to="/signup"
              className="block w-full bg-green-500 text-white py-3 px-6 rounded-lg hover:bg-green-600 transition-colors font-medium text-center"
            >
              無料で始める
            </Link>
          </div>
        </div>

        {/* 3つの特徴 */}
        <div className="text-center mb-12">
          <h2 className="text-2xl sm:text-3xl font-bold text-gray-900 mb-4">
            レコめしの特徴
          </h2>
          <p className="text-base text-gray-600">
            毎日の食材管理をもっと楽しく、もっとエコに
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8">
          {/* 写真で簡単認識 */}
          <div className="text-center bg-white rounded-lg p-6 shadow-sm border hover:shadow-md transition-shadow">
            <div className="inline-flex items-center justify-center w-12 h-12 bg-yellow-100 rounded-lg mb-4">
              <HiCamera className="text-2xl text-yellow-600" />
            </div>
            <h3 className="text-lg font-bold text-gray-900 mb-3">写真で簡単認識</h3>
            <p className="text-sm text-gray-600 leading-relaxed">
              冷蔵庫の写真を撮るだけで、AIが食材を自動認識。面倒な入力作業は一切不要です。
            </p>
          </div>

          {/* 最適レシピ提案 */}
          <div className="text-center bg-white rounded-lg p-6 shadow-sm border hover:shadow-md transition-shadow">
            <div className="inline-flex items-center justify-center w-12 h-12 bg-orange-100 rounded-lg mb-4">
              <FaSearch className="text-2xl text-orange-600" />
            </div>
            <h3 className="text-lg font-bold text-gray-900 mb-3">最適レシピ提案</h3>
            <p className="text-sm text-gray-600 leading-relaxed">
              今ある食材で作れるレシピを即座に提案。新しい料理にもチャレンジできます。
            </p>
          </div>

          {/* 買い物管理 */}
          <div className="text-center bg-white rounded-lg p-6 shadow-sm border hover:shadow-md transition-shadow">
            <div className="inline-flex items-center justify-center w-12 h-12 bg-green-100 rounded-lg mb-4">
              <FaShoppingCart className="text-2xl text-green-600" />
            </div>
            <h3 className="text-lg font-bold text-gray-900 mb-3">買い物管理</h3>
            <p className="text-sm text-gray-600 leading-relaxed">
              必要な食材を自動でリストアップ。効率的な買い物で食材ロスを削減します。
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default FeaturesSection;