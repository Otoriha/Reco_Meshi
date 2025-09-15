import { useState } from 'react'
import Dashboard from './pages/Dashboard/Dashboard'
import Login from './pages/Auth/Login'
import Signup from './pages/Auth/Signup'
import Header from './components/Header'
import { AuthProvider } from './contexts/AuthContext'
import { useAuth } from './hooks/useAuth'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Ingredients from './pages/Ingredients/Ingredients'
import RecipeHistory from './pages/RecipeHistory/RecipeHistory'
import Settings from './pages/Settings/Settings'
import RecipeList from './pages/Recipes/RecipeList'
import RecipeDetail from './pages/Recipes/RecipeDetail'
import ShoppingLists from './pages/ShoppingLists/ShoppingLists'
import ShoppingListDetail from './pages/ShoppingLists/ShoppingListDetail'

type AuthMode = 'login' | 'signup';

const isConfirmableEnabled = import.meta.env.VITE_CONFIRMABLE_ENABLED === 'true';

function AppContent() {
  const [authMode, setAuthMode] = useState<AuthMode>('login')
  const { isLoggedIn, setAuthState } = useAuth();

  const handleSwitchToLogin = () => setAuthMode('login')
  const handleSwitchToSignup = () => setAuthMode('signup')
  
  const handleSignupSuccess = () => {
    // 確認メール無効時は自動ログイン状態に
    if (!isConfirmableEnabled) {
      setAuthState(true);
    }
    console.log('Sign up successful')
  }

  const handleAuthModeChange = (mode: AuthMode) => {
    setAuthMode(mode);
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <BrowserRouter>
        <Header onAuthModeChange={handleAuthModeChange} />
        <main>
          {isLoggedIn ? (
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/ingredients" element={<Ingredients />} />
              <Route path="/recipes" element={<RecipeList />} />
              <Route path="/recipes/:id" element={<RecipeDetail />} />
              <Route path="/shopping-lists" element={<ShoppingLists />} />
              <Route path="/shopping-lists/:id" element={<ShoppingListDetail />} />
              <Route path="/recipe-history" element={<RecipeHistory />} />
              <Route path="/settings" element={<Settings />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          ) : authMode === 'login' ? (
            <Login onSwitchToSignup={handleSwitchToSignup} />
          ) : (
            <Signup 
              onSwitchToLogin={handleSwitchToLogin}
              onSignupSuccess={handleSignupSuccess}
            />
          )}
        </main>
      </BrowserRouter>
    </div>
  )
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  )
}

export default App
