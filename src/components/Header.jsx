// src/components/Header.jsx
import { LuSearch } from 'react-icons/lu';

const Header = ({ title, searchTerm, onSearchChange, searchDisabled = false, hideSearch = false, onBack }) => {
  return (
    <div className="db-header">
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        {onBack && (
          <button className="fac-back-btn" onClick={onBack}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
              <path d="M19 12H5"></path>
              <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
          </button>
        )}
        <h1 className="db-title">{title}</h1>
      </div>
      <div className="db-header-right">
        {!hideSearch && (
          <div className="db-search-bar">
            <LuSearch className="db-search-icon" />
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={onSearchChange}
              disabled={searchDisabled}
            />
          </div>
        )}
        <div className="db-avatar-img">
          <img
            src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=100&auto=format&fit=crop"
            alt="Profile"
          />
        </div>
      </div>
    </div>
  );
};

export default Header;