// src/App.jsx
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import FacultyManagement from './pages/FacultyManagement';
import BuildingManagement from './pages/BuildingManagement';
import UserManagementPage from './pages/UserManagementPage';
import OutdoorMarkersPage from './pages/OutdoorMarkersPage';
import HallsLabsPage from './pages/HallsLabsPage';
import InteractiveRoutePage from './pages/InteractiveRoutePage';
import ProfilePage from './pages/ProfilePage';
import AdminLogin from './pages/Auth/AdminLogin';
import AdminRegister from './pages/Auth/AdminRegister';
import { AuthProvider, useAuth } from './context/AuthContext';
import './styles/main.css';
import './styles/auth.css';

// Shows a loading spinner while Firebase auth state resolves
function LoadingScreen() {
  return (
    <div className="auth-loading">
      <div className="auth-loading-spinner" />
      <span>Loading…</span>
    </div>
  );
}

// Wraps routes that require an authenticated admin
function ProtectedRoute({ children }) {
  const { currentUser, loading } = useAuth();
  if (loading) return <LoadingScreen />;
  if (!currentUser) return <Navigate to="/login" replace />;
  return children;
}

// Redirects already-logged-in users away from login/register
function PublicRoute({ children }) {
  const { currentUser, loading } = useAuth();
  if (loading) return <LoadingScreen />;
  if (currentUser) return <Navigate to="/" replace />;
  return children;
}

function AppRoutes() {
  return (
    <Routes>
      {/* ── Public auth routes ── */}
      <Route path="/login" element={<PublicRoute><AdminLogin /></PublicRoute>} />
      <Route path="/register" element={<PublicRoute><AdminRegister /></PublicRoute>} />

      {/* ── Protected dashboard routes ── */}
      <Route path="/*" element={
        <ProtectedRoute>
          <div className="app-container">
            <Sidebar />
            <div className="main-content">
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/faculties" element={<FacultyManagement />} />
                <Route path="/buildings" element={<BuildingManagement />} />
                <Route path="/halls-labs" element={<HallsLabsPage />} />
                <Route path="/routing" element={<InteractiveRoutePage />} />
                <Route path="/users" element={<UserManagementPage />} />
                <Route path="/outdoor-markers" element={<OutdoorMarkersPage />} />
                <Route path="/profile" element={<ProfilePage />} />
              </Routes>
            </div>
          </div>
        </ProtectedRoute>
      } />
    </Routes>
  );
}

function App() {
  return (
    <AuthProvider>
      <Router>
        <AppRoutes />
      </Router>
    </AuthProvider>
  );
}

export default App;