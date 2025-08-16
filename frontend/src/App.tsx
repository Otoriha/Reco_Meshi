import { useState } from 'react'
import Dashboard from './pages/Dashboard/Dashboard'
import Login from './pages/Auth/Login'
import Signup from './pages/Auth/Signup'

type AuthMode = 'login' | 'signup';

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [authMode, setAuthMode] = useState<AuthMode>('login')

  const handleSwitchToLogin = () => setAuthMode('login')
  const handleSwitchToSignup = () => setAuthMode('signup')
  
  const handleSignupSuccess = () => {
    // 新規登録成功時の処理（必要に応じて追加）
    console.log('Sign up successful')
  }

  const handleLogout = () => {
    setIsLoggedIn(false)
    setAuthMode('login')
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <h1 className="text-2xl font-bold text-gray-900">
              レコめし
            </h1>
            <nav className="space-x-4">
              <button 
                onClick={() => isLoggedIn ? handleLogout() : setIsLoggedIn(true)}
                className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors"
              >
                {isLoggedIn ? 'ログアウト' : 'ログイン'}
              </button>
            </nav>
          </div>
        </div>
      </header>
      
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

export default App
