import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function ProtectedRoute() {
  const { isLoggedIn, isAuthResolved } = useAuth();
  const location = useLocation();

  // 認証判定中はローディング表示
  if (!isAuthResolved) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-gray-600">認証情報を確認中...</div>
      </div>
    );
  }

  if (!isLoggedIn) {
    const next = encodeURIComponent(
      location.pathname + location.search + location.hash
    );
    return <Navigate to={`/login?next=${next}`} replace />;
  }

  return <Outlet />;
}