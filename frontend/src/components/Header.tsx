import React from 'react';
import { useAuth } from '../hooks/useAuth';
import { Link } from 'react-router-dom';

interface HeaderProps {
  onAuthModeChange?: (mode: 'login' | 'signup') => void;
}

const Header: React.FC<HeaderProps> = ({ onAuthModeChange }) => {
  const { isLoggedIn, user, logout } = useAuth();

  const handleLogout = async () => {
    if (!confirm('ログアウトしますか？')) {
      return;
    }
    
    try {
      await logout();
      alert('ログアウトしました');
      if (onAuthModeChange) {
        onAuthModeChange('login');
      }
    } catch (error) {
      console.error('Logout error:', error);
      alert('ログアウトに失敗しました。もう一度お試しください。');
    }
  };

  const handleLogin = () => {
    if (onAuthModeChange) {
      onAuthModeChange('login');
    }
  };

  return (
    <>
      {/* Tailwind v4用のダミー要素 - 本番では削除 */}
      <div className="hidden bg-white shadow shadow-md shadow-lg text-gray-700 text-gray-900 hover:text-gray-900 space-x-4 max-w-7xl px-4 sm:px-6 lg:px-8 py-4 text-2xl font-bold bg-gray-50 bg-gray-100 p-6 rounded-lg text-xl font-semibold"></div>
      
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          <h1 className="text-2xl font-bold text-gray-900">
            <Link to="/" className="hover:opacity-80">レコめし</Link>
          </h1>
          <nav className="flex items-center space-x-4">
            {isLoggedIn && (
              <>
                <Link to="/" className="text-gray-700 hover:text-gray-900">ダッシュボード</Link>
                <Link to="/ingredients" className="text-gray-700 hover:text-gray-900">食材リスト</Link>
                <Link to="/recipes" className="text-gray-700 hover:text-gray-900">レシピ</Link>
                <Link to="/recipe-history" className="text-gray-700 hover:text-gray-900">レシピ履歴</Link>
                <Link to="/settings" className="text-gray-700 hover:text-gray-900">設定</Link>
              </>
            )}
            {isLoggedIn && user && (
              <span className="text-gray-700">
                {user.name}さん
              </span>
            )}
            <button 
              onClick={isLoggedIn ? handleLogout : handleLogin}
              className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors"
            >
              {isLoggedIn ? 'ログアウト' : 'ログイン'}
            </button>
          </nav>
        </div>
      </div>
    </header>
    </>
  );
};

export default Header;
