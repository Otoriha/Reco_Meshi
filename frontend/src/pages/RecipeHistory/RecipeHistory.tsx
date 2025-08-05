import React from 'react';

const RecipeHistory: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">
          レシピ履歴
        </h1>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600">過去のレシピ一覧、お気に入り、再作成</p>
        </div>
      </div>
    </div>
  );
};

export default RecipeHistory;