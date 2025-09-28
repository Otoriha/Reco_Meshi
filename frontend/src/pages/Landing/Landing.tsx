import React from 'react';
import HeroSection from '../../components/landing/HeroSection';
import FeaturesSection from '../../components/landing/FeaturesSection';
import HowToSection from '../../components/landing/HowToSection';
import CTASection from '../../components/landing/CTASection';

const Landing: React.FC = () => {
  return (
    <div className="min-h-screen">
      {/* ヒーローセクション */}
      <HeroSection />

      {/* 機能説明セクション */}
      <FeaturesSection />

      {/* 使い方説明セクション */}
      <HowToSection />

      {/* Call to Action セクション */}
      <CTASection />

      {/* フッター */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="col-span-1 md:col-span-2">
              <h3 className="text-2xl font-bold mb-4">レコめし</h3>
              <p className="text-gray-400 mb-4">
                食材を無駄なく使い切るAI食材管理アプリ。
                <br />
                今ある食材で美味しい料理を作りましょう。
              </p>
            </div>

            <div>
              <h4 className="text-lg font-semibold mb-4">プロダクト</h4>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#" className="hover:text-white transition-colors">機能紹介</a></li>
                <li><a href="#" className="hover:text-white transition-colors">使い方</a></li>
                <li><a href="#" className="hover:text-white transition-colors">よくある質問</a></li>
              </ul>
            </div>

            <div>
              <h4 className="text-lg font-semibold mb-4">会社情報</h4>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#" className="hover:text-white transition-colors">プライバシーポリシー</a></li>
                <li><a href="#" className="hover:text-white transition-colors">利用規約</a></li>
                <li><a href="#" className="hover:text-white transition-colors">お問い合わせ</a></li>
              </ul>
            </div>
          </div>

          <div className="border-t border-gray-800 pt-8 mt-8 text-center text-gray-400">
            <p>&copy; 2024 レコめし. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Landing;