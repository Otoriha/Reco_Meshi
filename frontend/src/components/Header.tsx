import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { Link, useLocation } from 'react-router-dom';
import { FaChevronDown } from 'react-icons/fa';

interface HeaderProps {
  onAuthModeChange?: (mode: 'login' | 'signup') => void;
}

const Header: React.FC<HeaderProps> = ({ onAuthModeChange }) => {
  const { isLoggedIn, isAuthResolved, user, logout } = useAuth();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const location = useLocation();

  const isLandingPage = location.pathname === '/';

  const isActivePath = (path: string) => {
    if (path === '/dashboard') {
      return location.pathname === '/dashboard' || (location.pathname === '/' && isLoggedIn);
    }
    return location.pathname.startsWith(path);
  };

  const getLinkClassName = (path: string) => {
    const baseClass = "text-white hover:text-green-100 font-medium";
    return isActivePath(path)
      ? `${baseClass} border-b-2 border-white`
      : baseClass;
  };

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
      <header className="bg-green-600 shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          <h1 className="text-2xl font-bold text-white">
            <Link to="/" className="hover:opacity-80">レコめし</Link>
          </h1>
          <nav className="flex items-center space-x-6">
            {/* ランディングページの場合 */}
            {isLandingPage ? (
              <div className="flex items-center space-x-4">
                {!isAuthResolved ? (
                  <div className="w-20 h-8">{/* スペーサー */}</div>
                ) : isLoggedIn ? (
                  <Link
                    to="/dashboard"
                    className="bg-white text-green-600 px-4 py-2 rounded-md hover:bg-green-50 transition-colors font-medium"
                  >
                    ダッシュボード
                  </Link>
                ) : (
                  <div className="flex items-center space-x-3">
                    <Link
                      to="/login"
                      className="text-white hover:text-green-100 font-medium"
                    >
                      ログイン
                    </Link>
                    <Link
                      to="/signup"
                      className="bg-white text-green-600 px-4 py-2 rounded-md hover:bg-green-50 transition-colors font-medium"
                    >
                      新規登録
                    </Link>
                  </div>
                )}
              </div>
            ) : (
              /* アプリ内ナビゲーション */
              <>
                {!isAuthResolved ? (
                  <div className="w-20 h-8">{/* スペーサー */}</div>
                ) : (
                  <>
                    {isLoggedIn && (
                      <>
                        <Link to="/dashboard" className={getLinkClassName('/dashboard')}>ホーム</Link>
                        <Link to="/ingredients" className={getLinkClassName('/ingredients')}>食材リスト</Link>
                        <Link to="/shopping-lists" className={getLinkClassName('/shopping-lists')}>買い物リスト</Link>
                        <Link to="/recipe-history" className={getLinkClassName('/recipe-history')}>レシピ履歴</Link>
                        <Link to="/favorite-recipes" className={getLinkClassName('/favorite-recipes')}>お気に入り</Link>
                        <Link to="/settings" className={getLinkClassName('/settings')}>設定（準備中）</Link>
                      </>
                    )}
                    {isLoggedIn && user ? (
                      <div className="relative">
                        <button
                          onClick={() => setShowUserMenu(!showUserMenu)}
                          className="flex items-center space-x-2 text-white hover:text-green-100 font-medium"
                        >
                          <span>{user.name || 'ユーザー'}</span>
                          <FaChevronDown className="w-3 h-3" />
                        </button>
                        {showUserMenu && (
                          <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-10">
                            <button
                              onClick={() => {
                                setShowUserMenu(false);
                                handleLogout();
                              }}
                              className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                            >
                              ログアウト
                            </button>
                          </div>
                        )}
                      </div>
                    ) : (
                      <button
                        onClick={handleLogin}
                        className="bg-white text-green-600 px-4 py-2 rounded-md hover:bg-green-50 transition-colors font-medium"
                      >
                        ログイン
                      </button>
                    )}
                  </>
                )}
              </>
            )}
          </nav>
        </div>
      </div>
    </header>
    </>
  );
};

export default Header;
