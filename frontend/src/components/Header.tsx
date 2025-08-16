import React from 'react';
import { useAuth } from '../hooks/useAuth';

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
    <header className="bg-white shadow">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          <h1 className="text-2xl font-bold text-gray-900">
            レコめし
          </h1>
          <nav className="flex items-center space-x-4">
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
  );
};

export default Header;