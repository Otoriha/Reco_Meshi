import React from 'react';
import { Link } from 'react-router-dom';

const CTASection: React.FC = () => {
  return (
    <section className="py-12 sm:py-16 bg-gradient-to-r from-green-600 to-green-700">
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
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center max-w-2xl mx-auto">
            {/* LINEで始める */}
            <button
              disabled
              className="w-full sm:w-auto bg-gray-400 text-gray-600 px-8 py-4 rounded-full cursor-not-allowed font-bold shadow-lg text-lg min-w-[250px]"
            >
              LINEで始める（準備中）
            </button>

            {/* Web版で始める */}
            <Link
              to="/signup"
              className="w-full sm:w-auto bg-white text-green-600 px-8 py-4 rounded-full hover:bg-green-50 transition-colors font-bold text-lg text-center min-w-[200px] shadow-lg"
            >
              WEB版で始める
            </Link>
          </div>

        </div>
      </div>
    </section>
  );
};

export default CTASection;