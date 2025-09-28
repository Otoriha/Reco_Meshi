import React from 'react';
import { Link } from 'react-router-dom';
import { FaLine } from 'react-icons/fa';
import { HiDesktopComputer } from 'react-icons/hi';
import phonePlaceholder from '../../assets/images/placeholder-phone.svg';

const HeroSection: React.FC = () => {
  return (
    <section className="bg-gradient-to-br from-green-50 to-green-100 py-16 sm:py-24">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* 左側のテキストコンテンツ */}
          <div className="space-y-8">
            <div className="space-y-4">
              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-gray-900 leading-tight">
                食材を
                <span className="text-green-600">無駄なく使い切る</span>
                <br />
                AI食材管理アプリ
              </h1>
              <p className="text-lg sm:text-xl text-gray-600 leading-relaxed">
                冷蔵庫の写真を撮るだけで食材を自動認識。
                <br />
                今ある食材で作れるレシピを提案し、
                <br />
                必要な買い物リストまで自動生成します。
              </p>
              <p className="text-sm text-gray-500">
                食材の無駄をなくして、毎日の料理をもっと楽しく。
              </p>
            </div>

            {/* LINE版とWEB版の選択ボタン */}
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="flex-1">
                <div className="bg-white rounded-lg p-6 border-2 border-green-200 hover:border-green-300 transition-colors">
                  <div className="flex items-center space-x-3 mb-3">
                    <FaLine className="text-2xl text-green-500" />
                    <span className="font-semibold text-gray-900">LINE版</span>
                  </div>
                  <p className="text-sm text-gray-600 mb-4">
                    LINEでかんたんに食材管理。
                    <br />
                    写真を送るだけで認識完了。
                  </p>
                  <button className="w-full bg-green-500 text-white py-2 px-4 rounded-md hover:bg-green-600 transition-colors font-medium">
                    LINEで今すぐ始める
                  </button>
                </div>
              </div>

              <div className="flex-1">
                <div className="bg-white rounded-lg p-6 border-2 border-gray-200 hover:border-gray-300 transition-colors">
                  <div className="flex items-center space-x-3 mb-3">
                    <HiDesktopComputer className="text-2xl text-gray-700" />
                    <span className="font-semibold text-gray-900">WEB版</span>
                  </div>
                  <p className="text-sm text-gray-600 mb-4">
                    ブラウザで詳細な食材管理。
                    <br />
                    在庫状況や履歴を細かく確認。
                  </p>
                  <Link
                    to="/signup"
                    className="block w-full bg-gray-700 text-white py-2 px-4 rounded-md hover:bg-gray-800 transition-colors font-medium text-center"
                  >
                    無料で始める
                  </Link>
                </div>
              </div>
            </div>
          </div>

          {/* 右側の画像 */}
          <div className="flex justify-center lg:justify-end">
            <div className="relative">
              <img
                src={phonePlaceholder}
                alt="レコめしアプリのプレビュー"
                className="w-80 h-auto max-w-full drop-shadow-2xl"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;