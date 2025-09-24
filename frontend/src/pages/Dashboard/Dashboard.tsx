import React, { useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { imageRecognitionApi } from '../../api/imageRecognition';
import { FaCamera, FaClipboardList, FaHistory, FaCog } from 'react-icons/fa';
import { HiSparkles } from 'react-icons/hi';
import RecipeSuggestModal from '../../components/recipes/RecipeSuggestModal';
import Toast from '../../components/Toast';
import type { Recipe } from '../../types/recipe';

const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadMessage, setUploadMessage] = useState<string | null>(null);

  // レシピ提案モーダル関連の状態
  const [isRecipeModalOpen, setIsRecipeModalOpen] = useState(false);

  // トースト通知関連の状態
  const [toastMessage, setToastMessage] = useState<string>('');
  const [toastType, setToastType] = useState<'success' | 'error' | 'info'>('info');
  const [isToastVisible, setIsToastVisible] = useState(false);

  const today = new Date();
  const formattedDate = `${today.getFullYear()}年${today.getMonth() + 1}月${today.getDate()}日 (${['日', '月', '火', '水', '木', '金', '土'][today.getDay()]})`;

  const handleImageUpload = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    setIsUploading(true);
    setUploadMessage(null);

    try {
      const images = Array.from(files);
      const response =
        images.length === 1
          ? await imageRecognitionApi.recognizeIngredients(images[0])
          : await imageRecognitionApi.recognizeMultipleIngredients(images);

      if (response.success) {
        const recognized = response.recognized_ingredients
          .map((ingredient) => `${ingredient.name}(${Math.round(ingredient.confidence * 100)}%)`)
          .join('、');
        setUploadMessage(
          recognized.length > 0
            ? `識別された食材: ${recognized}`
            : '食材を識別できませんでした。写真を確認してください。'
        );
      } else {
        setUploadMessage(response.message ?? '画像の認識に失敗しました。');
      }
    } catch (error) {
      console.error(error);
      setUploadMessage('画像のアップロードに失敗しました。通信環境をご確認ください。');
    } finally {
      setIsUploading(false);
      // 同じファイルを再度選択できるようにするために値をリセット
      event.target.value = '';
    }
  };

  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    setToastMessage(message);
    setToastType(type);
    setIsToastVisible(true);
  };

  const handleRecipeSuggest = () => {
    setIsRecipeModalOpen(true);
  };

  const handleRecipeGenerated = (recipe: Recipe) => {
    showToast(`「${recipe.title}」のレシピを生成しました！`, 'success');
  };

  const handleModalClose = () => {
    setIsRecipeModalOpen(false);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* 挨拶セクション */}
        <div className="mb-8">
          <div className="flex justify-between items-center mb-4">
            <h1 className="text-3xl font-bold text-gray-900">
              ようこそ、{user?.name || 'ユーザー'}さん！
            </h1>
            <p className="text-gray-600">{formattedDate}</p>
          </div>
          <div className="space-y-2">
            <p className="text-gray-700">今日も食材を無駄なく使い切りましょう。</p>
            <p className="text-gray-700">冷蔵庫の写真を撮って、今日のレシピを見つけてください。</p>
          </div>
        </div>

        {/* メインアクションカード */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* 冷蔵庫の写真を撮影 */}
          <div className="bg-white rounded-lg shadow-sm border-2 border-dashed border-green-300 p-8 hover:border-green-400 transition-colors">
            <div className="text-center">
              <div className="mb-4">
                <FaCamera className="mx-auto h-12 w-12 text-green-500" />
              </div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">冷蔵庫の写真を撮影</h2>
              <p className="text-gray-600 mb-2">冷蔵庫の中身が見えるように写真を撮ってください。</p>
              <p className="text-gray-600 mb-6">複数枚の写真をアップロードすることもできます。</p>

              <div className="space-y-4">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  multiple
                  className="hidden"
                  onChange={handleFileChange}
                />
                <button
                  onClick={handleImageUpload}
                  className="bg-green-600 text-white px-6 py-3 rounded-md hover:bg-green-700 transition-colors font-medium disabled:opacity-70"
                  disabled={isUploading}
                >
                  {isUploading ? 'アップロード中...' : '写真を選択'}
                </button>
                {uploadMessage && (
                  <p className="text-sm text-gray-700 whitespace-pre-line">{uploadMessage}</p>
                )}
              </div>
            </div>
          </div>

          {/* レシピを提案してもらう */}
          <div className="bg-white rounded-lg shadow-sm border-2 border-dashed border-pink-300 p-8 hover:border-pink-400 transition-colors">
            <div className="text-center">
              <div className="mb-4">
                <HiSparkles className="mx-auto h-12 w-12 text-pink-500" />
              </div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">レシピを提案してもらう</h2>
              <p className="text-gray-600 mb-2">今ある食材を伝えるだけで</p>
              <p className="text-gray-600 mb-6">AIが最適なレシピを提案します。</p>

              <div className="space-y-4">
                <div className="text-gray-700 font-medium">
                  <p>AIにレシピ提案を任せる</p>
                  <p className="text-sm text-gray-500">食材から自動でレシピを生成</p>
                </div>
                <button
                  onClick={handleRecipeSuggest}
                  className="bg-pink-500 text-white px-6 py-3 rounded-md hover:bg-pink-600 transition-colors font-medium"
                >
                  レシピ提案を依頼する
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* 機能紹介セクション */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Link to="/ingredients" className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow">
            <div className="text-center">
              <FaClipboardList className="mx-auto h-8 w-8 text-gray-600 mb-4" />
              <h3 className="text-lg font-bold text-gray-900 mb-2">在庫リスト</h3>
              <p className="text-gray-600 text-sm">現在の食材在庫を確認・編集できます</p>
            </div>
          </Link>

          <Link to="/recipe-history" className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow">
            <div className="text-center">
              <FaHistory className="mx-auto h-8 w-8 text-gray-600 mb-4" />
              <h3 className="text-lg font-bold text-gray-900 mb-2">レシピ履歴</h3>
              <p className="text-gray-600 text-sm">過去に作ったレシピを確認できます</p>
            </div>
          </Link>

          <Link to="/settings" className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow">
            <div className="text-center">
              <FaCog className="mx-auto h-8 w-8 text-gray-600 mb-4" />
              <h3 className="text-lg font-bold text-gray-900 mb-2">設定</h3>
              <p className="text-gray-600 text-sm">プロフィールや通知設定を管理できます</p>
            </div>
          </Link>
        </div>

        {/* レシピ提案モーダル */}
        <RecipeSuggestModal
          isOpen={isRecipeModalOpen}
          onClose={handleModalClose}
          onRecipeGenerated={handleRecipeGenerated}
        />

        {/* トースト通知 */}
        <Toast
          message={toastMessage}
          type={toastType}
          isVisible={isToastVisible}
          onClose={() => setIsToastVisible(false)}
        />
      </div>
    </div>
  );
};

export default Dashboard;
