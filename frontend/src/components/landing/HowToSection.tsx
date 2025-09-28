import React from 'react';
import { HiCamera, HiLightBulb, HiShoppingCart } from 'react-icons/hi';

const HowToSection: React.FC = () => {
  const steps = [
    {
      number: 1,
      icon: <HiCamera className="text-3xl text-white" />,
      title: 'アプリ登録',
      description: 'LINEまたはWebでアカウントを作成し、VR技術を駆使した管理システムを開始する。',
      bgColor: 'bg-blue-500'
    },
    {
      number: 2,
      icon: <HiLightBulb className="text-3xl text-white" />,
      title: '冷蔵庫を撮影',
      description: '冷蔵庫の中を撮影するか、手動で食材を入力。AI画像解析により食材をデータベースに自動登録する。',
      bgColor: 'bg-orange-500'
    },
    {
      number: 3,
      icon: <HiShoppingCart className="text-3xl text-white" />,
      title: 'レシピを提案で調理',
      description: '現在ある食材から作れるレシピをAIが提案。不足する材料は自動で買い物リストに追加される。',
      bgColor: 'bg-green-500'
    }
  ];

  return (
    <section className="py-16 sm:py-24 bg-gray-50">
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
        <div className="relative">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 lg:gap-12">
            {steps.map((step, index) => (
              <div key={step.number} className="text-center relative">
                {/* ステップアイコン */}
                <div className="relative mb-8">
                  <div className={`inline-flex items-center justify-center w-20 h-20 ${step.bgColor} rounded-full mb-4 mx-auto`}>
                    {step.icon}
                  </div>
                  <div className="absolute -top-2 -right-2 w-8 h-8 bg-gray-900 text-white rounded-full flex items-center justify-center text-sm font-bold">
                    {step.number}
                  </div>
                </div>

                {/* ステップ内容 */}
                <h3 className="text-xl font-bold text-gray-900 mb-4">
                  {step.title}
                </h3>
                <p className="text-gray-600 leading-relaxed">
                  {step.description}
                </p>

                {/* 矢印（最後のステップ以外） */}
                {index < steps.length - 1 && (
                  <div className="hidden md:flex absolute top-10 -right-6 lg:-right-8 transform translate-x-1/2 items-center justify-center z-10">
                    <svg
                      className="w-8 h-8 text-gray-400"
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