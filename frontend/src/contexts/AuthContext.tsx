import React, { createContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import { isAuthenticated, logout as logoutApi } from '../api/auth';
import type { UserData } from '../api/auth';
import {
  AUTH_TOKEN_CHANGED_EVENT,
  type AuthChangeDetail,
} from '../api/authEvents';

interface AuthContextType {
  isLoggedIn: boolean;
  isAuthResolved: boolean;
  user: UserData | null;
  login: (userData: UserData) => void;
  logout: () => Promise<void>;
  setAuthState: (isLoggedIn: boolean, user?: UserData) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

const getUserFromStorage = (): UserData | null => {
  try {
    const userData = localStorage.getItem('userData');
    return userData ? JSON.parse(userData) : null;
  } catch {
    return null;
  }
};

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [isLoggedIn, setIsLoggedIn] = useState(() => isAuthenticated());
  const [isAuthResolved, setIsAuthResolved] = useState(false);
  const [user, setUser] = useState<UserData | null>(() => getUserFromStorage());

  useEffect(() => {
    // 認証状態を解決済みにマーク
    setIsAuthResolved(true);

    // localStorageの変更を監視（他のタブでの操作や401インターセプタからの変更を検知）
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === 'authToken') {
        const hasToken = !!e.newValue;
        setIsLoggedIn(hasToken);
        if (!hasToken) {
          setUser(null);
        }
      }
    };

    // storage イベントは同一タブでは発火しないため、カスタムイベントも監視
    const handleAuthChange = (event: Event) => {
      const detail = (event as CustomEvent<AuthChangeDetail>).detail;
      const currentAuthStatus = isAuthenticated();

      // detailが明示的にisLoggedInを指定している場合はそれを使用
      // そうでなければ現在のトークンの状態を確認
      let newIsLoggedIn: boolean;
      if (detail?.isLoggedIn !== undefined) {
        newIsLoggedIn = detail.isLoggedIn;
      } else {
        newIsLoggedIn = currentAuthStatus;
      }

      setIsLoggedIn(newIsLoggedIn);

      // ユーザー情報の処理
      if (detail?.user !== undefined) {
        setUser(detail.user ?? null);
      } else if (!newIsLoggedIn) {
        setUser(null); // ログアウト時はユーザー情報をクリア
      }
    };

    window.addEventListener('storage', handleStorageChange);
    window.addEventListener(AUTH_TOKEN_CHANGED_EVENT, handleAuthChange as EventListener);

    return () => {
      window.removeEventListener('storage', handleStorageChange);
      window.removeEventListener(AUTH_TOKEN_CHANGED_EVENT, handleAuthChange as EventListener);
    };
  }, []);

  const login = (userData: UserData) => {
    setIsLoggedIn(true);
    setUser(userData);
  };

  const logout = async () => {
    try {
      await logoutApi();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setIsLoggedIn(false);
      setUser(null);
      // ログアウト後は認証状態を強制的に同期
      setTimeout(() => {
        setIsLoggedIn(isAuthenticated());
      }, 100);
    }
  };

  const setAuthState = (loggedIn: boolean, userData?: UserData) => {
    setIsLoggedIn(loggedIn);
    setUser(userData || null);
  };

  const value: AuthContextType = {
    isLoggedIn,
    isAuthResolved,
    user,
    login,
    logout,
    setAuthState,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthContext;
