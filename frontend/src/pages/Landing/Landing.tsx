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
      <footer className="bg-gray-900 text-white py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* フッターリンク */}
          <div className="flex flex-wrap justify-center gap-8 mb-6">
            <a href="#" className="text-gray-400 hover:text-white transition-colors text-sm">利用規約</a>
            <a href="#" className="text-gray-400 hover:text-white transition-colors text-sm">プライバシーポリシー</a>
            <a href="#" className="text-gray-400 hover:text-white transition-colors text-sm">お問い合わせ</a>
            <a href="#" className="text-gray-400 hover:text-white transition-colors text-sm">ヘルプ</a>
          </div>

          {/* コピーライト */}
          <div className="text-center text-gray-400 text-sm">
            <p>&copy; 2025 レコめし. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Landing;