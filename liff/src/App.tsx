import React from 'react'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import PrivateRoute from './components/PrivateRoute'
import Home from './pages/Home/Home'
import Ingredients from './pages/Ingredients/Ingredients'
import RecipeHistory from './pages/RecipeHistory/RecipeHistory'
import Settings from './pages/Settings/Settings'

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route element={<PrivateRoute />}>
            <Route path="/ingredients" element={<Ingredients />} />
            <Route path="/recipe-history" element={<RecipeHistory />} />
            <Route path="/settings" element={<Settings />} />
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}

export default App
