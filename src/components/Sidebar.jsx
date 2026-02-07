// src/components/Sidebar.jsx
import { NavLink } from 'react-router-dom';
import {
  FaTachometerAlt,
  FaBuilding,
  FaUsers,
  FaRoute,
  FaChartBar,
  FaCog,
  FaUniversity,
  FaDoorOpen
} from 'react-icons/fa';

const Sidebar = () => {
  return (
    <div className="sidebar">
      <div className="logo">
        <div className="badge">NA</div>
        <div>NaviAdmin</div>
      </div>

      <div className="nav-section">
        <div className="nav-title">Navigation</div>
        <ul className="nav-links">
          <li>
            <NavLink to="/" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaTachometerAlt /> Dashboard
            </NavLink>
          </li>
          <li>
            <NavLink to="/buildings" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaBuilding /> Buildings
            </NavLink>
          </li>
          <li>
            <NavLink to="/faculties" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaUniversity /> Faculties
            </NavLink>
          </li>
          <li>
            <NavLink to="/halls-labs" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaDoorOpen /> Halls & Labs
            </NavLink>
          </li>
          <li>
            <NavLink to="/routing" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaRoute /> Routing
            </NavLink>
          </li>
        </ul>
      </div>

      <div className="nav-section">
        <div className="nav-title">Management</div>
        <ul className="nav-links">
          <li>
            <NavLink to="/analytics" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaChartBar /> Analytics
            </NavLink>
          </li>
        </ul>
      </div>

      <div className="nav-section">
        <div className="nav-title">System</div>
        <ul className="nav-links">
          <li>
            <NavLink to="/users" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaUsers /> User Management
            </NavLink>
          </li>
          <li>
            <NavLink to="/settings" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaCog /> Settings
            </NavLink>
          </li>
        </ul>
      </div>
    </div>
  );
};

export default Sidebar;