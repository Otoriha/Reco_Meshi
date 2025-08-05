import React from 'react';

const Dashboard: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">
          ダッシュボード
        </h1>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-semibold mb-4">食材サマリー</h2>
            <p className="text-gray-600">冷蔵庫の在庫状況を確認</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-semibold mb-4">おすすめレシピ</h2>
            <p className="text-gray-600">今ある食材で作れるレシピ</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-semibold mb-4">クイックアクション</h2>
            <p className="text-gray-600">よく使う機能へのショートカット</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;