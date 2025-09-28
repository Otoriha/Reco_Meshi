import React from 'react';
import { Link } from 'react-router-dom';
import { FaLine } from 'react-icons/fa';

const CTASection: React.FC = () => {
  return (
    <section className="py-16 sm:py-24 bg-gradient-to-r from-green-600 to-green-700">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          {/* メインタイトル */}
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-6">
            今すぐ始めよう
          </h2>
          <p className="text-lg sm:text-xl text-green-100 mb-4 max-w-3xl mx-auto">
            食材の無駄を減らし、クリエイティブな料理を始める第一歩。
          </p>
          <p className="text-base text-green-200 mb-12 max-w-2xl mx-auto">
            今すぐアカウントを作成して、今ある食材を有効活用しましょう。
          </p>

          {/* CTAボタン */}
          <div className="flex flex-col sm:flex-row gap-6 justify-center items-center max-w-2xl mx-auto">
            {/* LINEで始める */}
            <div className="w-full sm:w-auto">
              <button className="w-full sm:w-auto bg-white text-green-600 px-8 py-4 rounded-lg hover:bg-green-50 transition-colors font-bold text-lg shadow-lg flex items-center justify-center space-x-3 min-w-[200px]">
                <FaLine className="text-2xl" />
                <span>LINEで始める</span>
              </button>
              <p className="text-green-100 text-sm mt-2">
                LINEアカウントでかんたん登録
              </p>
            </div>

            <div className="hidden sm:block text-green-200 text-lg font-medium">
              または
            </div>

            {/* Web版で始める */}
            <div className="w-full sm:w-auto">
              <Link
                to="/signup"
                className="block w-full sm:w-auto bg-green-800 text-white px-8 py-4 rounded-lg hover:bg-green-900 transition-colors font-bold text-lg shadow-lg text-center min-w-[200px]"
              >
                Web版で始める
              </Link>
              <p className="text-green-100 text-sm mt-2">
                メールアドレスで無料登録
              </p>
            </div>
          </div>

          {/* 追加情報 */}
          <div className="mt-12 grid grid-cols-1 sm:grid-cols-3 gap-6 text-center">
            <div>
              <div className="text-2xl font-bold text-white mb-2">完全無料</div>
              <p className="text-green-100 text-sm">
                基本機能はすべて無料でご利用いただけます
              </p>
            </div>
            <div>
              <div className="text-2xl font-bold text-white mb-2">簡単登録</div>
              <p className="text-green-100 text-sm">
                1分で登録完了、すぐに食材管理を始められます
              </p>
            </div>
            <div>
              <div className="text-2xl font-bold text-white mb-2">安心利用</div>
              <p className="text-green-100 text-sm">
                個人情報は適切に保護され、安全にご利用いただけます
              </p>
            </div>
          </div>

          {/* 既存ユーザー向け */}
          <div className="mt-12 pt-8 border-t border-green-500">
            <p className="text-green-100 mb-4">
              すでにアカウントをお持ちの方は
            </p>
            <Link
              to="/login"
              className="inline-block text-white underline hover:text-green-100 transition-colors font-medium"
            >
              こちらからログイン
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
};

export default CTASection;