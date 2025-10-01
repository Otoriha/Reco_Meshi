import React from 'react';
import { Link } from 'react-router-dom';
import { FaLine } from 'react-icons/fa';
import { HiDesktopComputer } from 'react-icons/hi';
import phonePlaceholder from '../../assets/images/placeholder-phone.svg';

const HeroSection: React.FC = () => {
  return (
    <section className="bg-gradient-to-br from-green-50 to-green-100 py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12 items-center">
          {/* 左側のテキストコンテンツ */}
          <div className="space-y-6">
            <div className="space-y-4">
              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900 leading-tight">
                食材を
                <span className="text-green-600">無駄なく使い切る</span>
                <br />
                AI食材管理アプリ
              </h1>
              <p className="text-base sm:text-lg text-gray-600 leading-relaxed">
                冷蔵庫の写真を撮るだけで食材を自動認識。
                <br />
                今ある食材で作れるレシピを提案します。
                <br />
                食材ロスを減らして、家計も地球も守りましょう。
              </p>
            </div>

            {/* あなたに合った使い方を選べます */}
            <div className="space-y-3">
              <p className="text-sm font-medium text-gray-800">
                あなたに合った使い方を選べます
              </p>

              {/* LINE版とWEB版の選択ボタン */}
              <div className="flex flex-col sm:flex-row gap-3">
                <div className="flex-1">
                  <div className="bg-gray-100 rounded-xl p-4 border border-gray-300 relative opacity-75">
                    {/* 準備中リボン */}
                    <div className="absolute -top-2 -right-2 bg-gray-500 text-white text-xs px-2 py-1 rounded-full font-medium">
                      準備中
                    </div>
                    <div className="flex items-center space-x-2 mb-2">
                      <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center">
                        <FaLine className="text-sm text-gray-500" />
                      </div>
                      <span className="font-semibold text-gray-600 text-sm">LINE版</span>
                    </div>
                    <p className="text-xs text-gray-500 mb-3">
                      気軽に! サクッと使いたい方へ
                    </p>
                    <button
                      disabled
                      className="w-full bg-gray-400 text-gray-600 py-2 px-3 rounded-lg cursor-not-allowed font-medium text-sm"
                    >
                      近日公開予定
                    </button>
                  </div>
                </div>

                <div className="flex-1">
                  <div className="bg-white rounded-xl p-4 border border-green-200 hover:border-green-300 transition-colors relative">
                    {/* おすすめリボン */}
                    <div className="absolute -top-2 -right-2 bg-green-500 text-white text-xs px-2 py-1 rounded-full font-medium">
                      おすすめ
                    </div>
                    <div className="flex items-center space-x-2 mb-2">
                      <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                        <HiDesktopComputer className="text-sm text-green-600" />
                      </div>
                      <span className="font-semibold text-gray-900 text-sm">WEB版</span>
                    </div>
                    <p className="text-xs text-gray-600 mb-3">
                      しっかり管理したい方へ
                    </p>
                    <Link
                      to="/signup"
                      className="block w-full bg-green-500 text-white py-2 px-3 rounded-lg hover:bg-green-600 transition-colors font-medium text-center text-sm"
                    >
                      無料で新規登録
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* 右側の画像 */}
          <div className="flex justify-center lg:justify-end order-first lg:order-last">
            <div className="relative">
              <img
                src={phonePlaceholder}
                alt="レコめしアプリのプレビュー"
                className="w-64 sm:w-80 h-auto max-w-full drop-shadow-2xl"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;