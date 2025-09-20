import { apiClient } from './client';
import axios from 'axios';
import { dispatchAuthTokenChanged } from './authEvents';

const isConfirmableEnabled = import.meta.env.VITE_CONFIRMABLE_ENABLED === 'true';

export interface SignupData {
  name: string;
  email: string;
  password: string;
  passwordConfirmation: string;
}

export interface LoginData {
  email: string;
  password: string;
}

export interface UserData {
  id: number;
  name: string;
  email: string;
  created_at: string;
  updated_at: string;
}

export interface AuthResponse {
  status: {
    code: number;
    message: string;
  };
  data?: UserData; // Optional because confirmable enabled returns no data
}

export interface AuthError {
  status?: {
    message: string;
  };
  error?: string;
}

export const signup = async (data: SignupData): Promise<UserData | void> => {
  try {
    const response = await apiClient.post<AuthResponse>('/auth/signup', {
      user: {
        name: data.name,
        email: data.email,
        password: data.password,
        password_confirmation: data.passwordConfirmation,
      },
    });

    const userData = response.data.data;

    // AuthorizationヘッダーからJWTトークンを取得
    const authHeader = response.headers['authorization'];
    if (authHeader && !isConfirmableEnabled) {
      // 確認メール無効時のみトークンを保存（自動ログイン）
      const token = authHeader.replace('Bearer ', '');
      localStorage.setItem('authToken', token);

      if (!userData) {
        localStorage.removeItem('authToken');
        dispatchAuthTokenChanged({ isLoggedIn: false, user: null });
        throw new Error('ユーザー情報の取得に失敗しました。');
      }

      // AuthContextに認証状態の変更を通知
      dispatchAuthTokenChanged({
        isLoggedIn: true,
        user: userData,
      });
    }
    // 確認メール有効時はトークンを保存せず、メール確認後にログインしてもらう

    // Return user data if available, otherwise void for confirmable enabled case
    return userData;
  } catch (error: unknown) {
    if (axios.isAxiosError(error) && error.response?.data) {
      const errorData = error.response.data as AuthError;
      // サインアップエラー（422）はstatus.messageに詳細メッセージが含まれる
      if (errorData.status?.message) {
        throw new Error(errorData.status.message);
      }
      // その他のエラー
      if (errorData.error) {
        throw new Error(errorData.error);
      }
    }
    throw new Error('サインアップに失敗しました。もう一度お試しください。');
  }
};

export const login = async (data: LoginData): Promise<UserData> => {
  try {
    const response = await apiClient.post<AuthResponse>('/auth/login', {
      user: {
        email: data.email,
        password: data.password,
      },
    });

    const userData = response.data.data;

    if (!userData) {
      throw new Error('ログイン情報の取得に失敗しました。');
    }

    // AuthorizationヘッダーからJWTトークンを取得
    const authHeader = response.headers['authorization'];
    if (authHeader) {
      // "Bearer "を除去してlocalStorageに保存
      const token = authHeader.replace('Bearer ', '');
      localStorage.setItem('authToken', token);

      // AuthContextに認証状態の変更を通知
      dispatchAuthTokenChanged({
        isLoggedIn: true,
        user: userData,
      });
    }

    return userData;
  } catch (error: unknown) {
    if (axios.isAxiosError(error) && error.response?.data) {
      const errorData = error.response.data as AuthError;
      // ログインエラー（401）はerrorフィールドに含まれる
      if (errorData.error) {
        throw new Error(errorData.error);
      }
      if (errorData.status?.message) {
        throw new Error(errorData.status.message);
      }
    }
    throw new Error('ログインに失敗しました。メールアドレスとパスワードを確認してください。');
  }
};

export const logout = async (): Promise<void> => {
  try {
    await apiClient.delete('/auth/logout');
  } catch (error) {
    // ログアウトはトークンクリアが主目的なので、APIエラーは無視
    console.warn('Logout API error:', error);
  } finally {
    // 必ずlocalStorageをクリア
    localStorage.removeItem('authToken');

    // AuthContextに認証状態の変更を通知
    dispatchAuthTokenChanged({ isLoggedIn: false, user: null });
  }
};

// トークンの存在チェック
export const isAuthenticated = (): boolean => {
  return !!localStorage.getItem('authToken');
};

// 認証状態をクリア
export const clearAuth = (): void => {
  localStorage.removeItem('authToken');

  // AuthContextに認証状態の変更を通知
  dispatchAuthTokenChanged({ isLoggedIn: false, user: null });
};
