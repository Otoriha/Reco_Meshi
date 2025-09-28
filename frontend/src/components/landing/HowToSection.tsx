import React from 'react';
import { HiCamera, HiLightBulb, HiShoppingCart } from 'react-icons/hi';

const HowToSection: React.FC = () => {
  const steps = [
    {
      number: 1,
      icon: <HiCamera className="text-2xl text-white" />,
      title: 'アプリに登録',
      description: 'LINEならば友だち追加をするだけ、WEB版も簡単登録ですぐに始められます。',
      bgColor: 'bg-green-500',
      image: '📱'
    },
    {
      number: 2,
      icon: <HiLightBulb className="text-2xl text-white" />,
      title: '冷蔵庫を撮影',
      description: '冷蔵庫の中を写真に撮って送信、またはAI自動認識により食材を在庫リストに登録します。',
      bgColor: 'bg-orange-500',
      image: '📸'
    },
    {
      number: 3,
      icon: <HiShoppingCart className="text-2xl text-white" />,
      title: 'レシピを選んで調理',
      description: '提案されたレシピから作りたいものを選ぶだけ。少ない食材でも美味しいものが作れます。',
      bgColor: 'bg-green-500',
      image: '🍽️'
    }
  ];

  return (
    <section className="py-12 sm:py-16 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* セクションタイトル */}
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">
            かんたん3ステップ
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            食材管理からレシピ提案まで、簡単3ステップで完了
          </p>
        </div>

        {/* ステップ */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {steps.map((step, index) => (
            <div key={step.number} className="relative">
              {/* ステップカード */}
              <div className="bg-white rounded-xl p-6 shadow-sm border text-left">
                {/* ステップ番号 */}
                <div className="flex items-center space-x-4 mb-4">
                  <div className="w-10 h-10 bg-green-500 text-white rounded-full flex items-center justify-center font-bold text-lg">
                    {step.number}
                  </div>
                  <h3 className="text-lg font-bold text-gray-900">
                    {step.title}
                  </h3>
                </div>

                {/* ステップ説明 */}
                <p className="text-sm text-gray-600 leading-relaxed mb-4">
                  {step.description}
                </p>
              </div>

              {/* 画像アイコン（右側に配置） */}
              <div className="absolute -top-2 -right-2 text-4xl">
                {step.image}
              </div>

              {/* 矢印（最後のステップ以外） */}
              {index < steps.length - 1 && (
                <div className="hidden md:block absolute top-1/2 -right-4 transform -translate-y-1/2 z-10">
                  <svg
                    className="w-6 h-6 text-gray-300"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* 追加説明 */}
        <div className="mt-16 text-center">
          <div className="bg-white rounded-lg p-8 shadow-sm border">
            <h3 className="text-xl font-bold text-gray-900 mb-4">
              もっと詳しく知りたい方へ
            </h3>
            <p className="text-gray-600 mb-6">
              レコめしの機能をもっと詳しく知りたい方は、公式LINEアカウントを友だち追加するか、
              <br className="hidden sm:inline" />
              Webサイトで詳細機能をご確認ください。
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button className="bg-green-500 text-white px-6 py-3 rounded-lg hover:bg-green-600 transition-colors font-medium">
                LINEで体験する
              </button>
              <button className="bg-gray-700 text-white px-6 py-3 rounded-lg hover:bg-gray-800 transition-colors font-medium">
                Web版を試す
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HowToSection;