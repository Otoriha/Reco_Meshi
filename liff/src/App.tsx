import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import PrivateRoute from './components/PrivateRoute'
import Home from './pages/Home/Home'
import Ingredients from './pages/Ingredients/Ingredients'
import RecipeHistory from './pages/RecipeHistory/RecipeHistory'
import Settings from './pages/Settings/Settings'
import RecipeList from './pages/Recipes/RecipeList'
import RecipeDetail from './pages/Recipes/RecipeDetail'
import ShoppingLists from './pages/ShoppingLists/ShoppingLists'
import ShoppingListDetail from './pages/ShoppingLists/ShoppingListDetail'

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route element={<PrivateRoute />}>
            <Route path="/ingredients" element={<Ingredients />} />
            <Route path="/recipes" element={<RecipeList />} />
            <Route path="/recipes/:id" element={<RecipeDetail />} />
            <Route path="/recipe-history" element={<RecipeHistory />} />
            <Route path="/shopping-lists" element={<ShoppingLists />} />
            <Route path="/shopping-lists/:id" element={<ShoppingListDetail />} />
            <Route path="/settings" element={<Settings />} />
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}

export default App
