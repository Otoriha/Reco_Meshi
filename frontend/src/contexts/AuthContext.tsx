import React, { createContext, useState, useEffect, ReactNode } from 'react';
import { isAuthenticated, logout as logoutApi, UserData } from '../api/auth';

interface AuthContextType {
  isLoggedIn: boolean;
  user: UserData | null;
  login: (userData: UserData) => void;
  logout: () => Promise<void>;
  setAuthState: (isLoggedIn: boolean, user?: UserData) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [user, setUser] = useState<UserData | null>(null);

  useEffect(() => {
    setIsLoggedIn(isAuthenticated());
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
    }
  };

  const setAuthState = (loggedIn: boolean, userData?: UserData) => {
    setIsLoggedIn(loggedIn);
    setUser(userData || null);
  };

  const value: AuthContextType = {
    isLoggedIn,
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