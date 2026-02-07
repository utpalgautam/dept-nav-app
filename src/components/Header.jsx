// src/components/Header.jsx
import { FaBell } from 'react-icons/fa';

const Header = ({ title }) => {
  return (
    <div className="header">
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <h1>{title}</h1>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <input className="form-control" placeholder="Search buildings, users, or routes..." style={{ width: 320, background: '#f8fafc' }} />
        </div>

        <button className="btn btn-outline" title="Notifications" style={{ padding: '0.65rem', borderRadius: '50%', border: 'none', background: 'transparent' }}>
          <FaBell size={18} color="var(--gray-color)" />
        </button>

        <div className="user-profile">
          <div className="user-avatar">AR</div>
          <div style={{ textAlign: 'left' }}>
            <div style={{ fontWeight: 600 }}>Alex Rivera</div>
            <div style={{ fontSize: '0.825rem', color: 'var(--muted-gray)' }}>Super Admin</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Header;