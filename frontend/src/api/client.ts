import axios from 'axios';
import { dispatchAuthTokenChanged } from './authEvents';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 多重リダイレクト防止フラグ
let isRedirectingToLogin = false;

// Response interceptor to handle 401 errors
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401 && !isRedirectingToLogin) {
      const { pathname } = window.location;
      // /loginページ上での401はリダイレクトしない
      if (!pathname.startsWith('/login')) {
        isRedirectingToLogin = true;
        localStorage.removeItem('authToken');

        // AuthContextに認証状態の変更を通知
        dispatchAuthTokenChanged({ isLoggedIn: false, user: null });

        const { pathname, search, hash } = window.location;
        const next = encodeURIComponent(`${pathname}${search}${hash}`);
        window.location.replace(`/login?next=${next}`);

        // フラグリセット（タイマーで安全に）
        setTimeout(() => {
          isRedirectingToLogin = false;
        }, 1000);
      } else {
        // /loginページ上ではトークンのクリアのみ
        localStorage.removeItem('authToken');

        // AuthContextに認証状態の変更を通知
        dispatchAuthTokenChanged({ isLoggedIn: false, user: null });

        console.warn('Authentication failed on login page. Token cleared.');
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;
