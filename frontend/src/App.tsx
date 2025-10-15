import Dashboard from './pages/Dashboard/Dashboard'
import Landing from './pages/Landing/Landing'
import Login from './pages/Auth/Login'
import Signup from './pages/Auth/Signup'
import LineCallback from './pages/Auth/LineCallback'
import Header from './components/Header'
import { AuthProvider } from './contexts/AuthContext'
import { BrowserRouter, Routes, Route, useNavigate, useLocation } from 'react-router-dom'
import Ingredients from './pages/Ingredients/Ingredients'
import RecipeHistory from './pages/RecipeHistory/RecipeHistory'
import Settings from './pages/Settings/Settings'
import RecipeList from './pages/Recipes/RecipeList'
import RecipeDetail from './pages/Recipes/RecipeDetail'
import ShoppingLists from './pages/ShoppingLists/ShoppingLists'
import ShoppingListDetail from './pages/ShoppingLists/ShoppingListDetail'
import ProtectedRoute from './components/ProtectedRoute'
import NotFound from './components/NotFound'
import Terms from './pages/Legal/Terms'
import Privacy from './pages/Legal/Privacy'

type AuthMode = 'login' | 'signup';

function AppContent() {
  const navigate = useNavigate()
  const location = useLocation()

  const handleSwitchToLogin = () => {
    navigate('/login')
  }

  const handleSwitchToSignup = () => {
    navigate('/signup')
  }

  const handleSignupSuccess = () => {
    // サインアップ成功時の処理は既にauth.tsで実行済み
    // ここでは特に何もしない（認証状態はイベント経由で更新される）
    console.log('Sign up successful')
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const handleAuthModeChange = (_mode: AuthMode) => {
    // 今はルーティングベースなので何もしない
  }

  const isLandingPage = location.pathname === '/';

  return (
    <div className={`min-h-screen ${isLandingPage ? '' : 'bg-gray-100'}`}>
        <Header onAuthModeChange={handleAuthModeChange} />
        <main>
          <Routes>
            {/* パブリックルート */}
            <Route path="/" element={<Landing />} />
            <Route
              path="/login"
              element={<Login onSwitchToSignup={handleSwitchToSignup} />}
            />
            <Route
              path="/signup"
              element={
                <Signup
                  onSwitchToLogin={handleSwitchToLogin}
                  onSignupSuccess={handleSignupSuccess}
                />
              }
            />
            <Route path="/terms" element={<Terms />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="/auth/line/callback" element={<LineCallback />} />

            {/* 保護ルート */}
            <Route element={<ProtectedRoute />}>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/ingredients" element={<Ingredients />} />
              <Route path="/recipes" element={<RecipeList />} />
              <Route path="/recipes/:id" element={<RecipeDetail />} />
              <Route path="/shopping-lists" element={<ShoppingLists />} />
              <Route path="/shopping-lists/:id" element={<ShoppingListDetail />} />
              <Route path="/recipe-history" element={<RecipeHistory />} />
              <Route path="/settings" element={<Settings />} />
            </Route>

            {/* 404ルート */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </main>
    </div>
  )
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppContent />
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App
