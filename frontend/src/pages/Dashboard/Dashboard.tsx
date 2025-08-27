import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';

const Dashboard: React.FC = () => {
  const { user } = useAuth();

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="p-6">
        <div className="max-w-7xl mx-auto">
          <div className="mb-6">
            <h1 className="text-3xl font-bold text-gray-900">ダッシュボード</h1>
            <p className="text-gray-600 mt-2">ようこそ、{user?.name || 'ユーザー'}さん</p>
          </div>
          
          <div className="bg-white rounded-lg shadow p-6 mb-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <Link 
                to="/ingredients" 
                className="block p-4 bg-blue-50 border border-blue-200 rounded-lg hover:bg-blue-100 transition-colors"
              >
                <h2 className="text-lg font-semibold text-blue-900 mb-2">食材リスト</h2>
                <p className="text-blue-700 text-sm">冷蔵庫の在庫を管理</p>
              </Link>
              
              <Link 
                to="/recipe-history" 
                className="block p-4 bg-emerald-50 border border-emerald-200 rounded-lg hover:bg-emerald-100 transition-colors"
              >
                <h2 className="text-lg font-semibold text-emerald-900 mb-2">レシピ履歴</h2>
                <p className="text-emerald-700 text-sm">過去のレシピを確認</p>
              </Link>
              
              <Link 
                to="/settings" 
                className="block p-4 bg-gray-50 border border-gray-200 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <h2 className="text-lg font-semibold text-gray-700 mb-2">設定</h2>
                <p className="text-gray-600 text-sm">アカウント設定</p>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;