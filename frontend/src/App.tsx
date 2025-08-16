import { useState } from 'react'
import Dashboard from './pages/Dashboard/Dashboard'
import Login from './pages/Auth/Login'
import Signup from './pages/Auth/Signup'
import Header from './components/Header'
import { AuthProvider } from './contexts/AuthContext'
import { useAuth } from './hooks/useAuth'

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
      <Header onAuthModeChange={handleAuthModeChange} />
      
      <main>
        {isLoggedIn ? (
          <Dashboard />
        ) : authMode === 'login' ? (
          <Login onSwitchToSignup={handleSwitchToSignup} />
        ) : (
          <Signup 
            onSwitchToLogin={handleSwitchToLogin}
            onSignupSuccess={handleSignupSuccess}
          />
        )}
      </main>
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
