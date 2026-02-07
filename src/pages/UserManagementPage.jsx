// src/pages/UserManagementPage.jsx
import { useState } from 'react';
import Header from '../components/Header';
import { FaUsers, FaFilter, FaDownload, FaSort, FaSortUp, FaSortDown, FaKey, FaBan, FaCheckCircle, FaSearch } from 'react-icons/fa';

const UserManagementPage = () => {
  // Mock user data
  const initialUsers = [
    {
      id: '1',
      email: 'admin@university.edu',
      name: 'John Smith',
      role: 'Admin',
      registrationDate: '2025-12-15',
      lastLogin: '2026-02-07T14:30:00',
      status: 'active',
      department: 'IT Services'
    },
    {
      id: '2',
      email: 'sarah.johnson@university.edu',
      name: 'Sarah Johnson',
      role: 'Manager',
      registrationDate: '2026-01-10',
      lastLogin: '2026-02-07T09:15:00',
      status: 'active',
      department: 'Facilities Management'
    },
    {
      id: '3',
      email: 'mike.wilson@university.edu',
      name: 'Mike Wilson',
      role: 'Staff',
      registrationDate: '2026-01-22',
      lastLogin: '2026-02-06T16:45:00',
      status: 'active',
      department: 'Engineering'
    },
    {
      id: '4',
      email: 'emma.davis@university.edu',
      name: 'Emma Davis',
      role: 'Viewer',
      registrationDate: '2025-11-05',
      lastLogin: '2026-02-05T11:20:00',
      status: 'inactive',
      department: 'Library Services'
    },
    {
      id: '5',
      email: 'james.brown@university.edu',
      name: 'James Brown',
      role: 'Manager',
      registrationDate: '2025-10-18',
      lastLogin: '2026-02-07T13:00:00',
      status: 'active',
      department: 'Student Affairs'
    },
    {
      id: '6',
      email: 'lisa.anderson@university.edu',
      name: 'Lisa Anderson',
      role: 'Staff',
      registrationDate: '2026-01-30',
      lastLogin: '2026-02-04T10:30:00',
      status: 'active',
      department: 'Administration'
    },
    {
      id: '7',
      email: 'robert.taylor@university.edu',
      name: 'Robert Taylor',
      role: 'Viewer',
      registrationDate: '2025-12-20',
      lastLogin: '2026-01-28T14:15:00',
      status: 'inactive',
      department: 'Research'
    },
    {
      id: '8',
      email: 'jennifer.white@university.edu',
      name: 'Jennifer White',
      role: 'Staff',
      registrationDate: '2026-02-01',
      lastLogin: '2026-02-07T08:45:00',
      status: 'active',
      department: 'Academic Affairs'
    }
  ];

  const [users, setUsers] = useState(initialUsers);
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState('All');
  const [statusFilter, setStatusFilter] = useState('All');
  const [sortColumn, setSortColumn] = useState('email');
  const [sortDirection, setSortDirection] = useState('asc');
  const [showDeactivateModal, setShowDeactivateModal] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);

  // Role color mapping
  const roleColors = {
    'Admin': { bg: '#f3e8ff', color: '#6b21a8', border: '#8b5cf6' },
    'Manager': { bg: '#dbeafe', color: '#1e40af', border: '#3b82f6' },
    'Staff': { bg: '#d1fae5', color: '#065f46', border: '#10b981' },
    'Viewer': { bg: '#f3f4f6', color: '#374151', border: '#6b7280' }
  };

  // Format date
  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
  };

  // Get relative time
  const getRelativeTime = (dateString) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now - date) / 1000);

    if (diffInSeconds < 60) return 'Just now';
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)} mins ago`;
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)} hours ago`;
    if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)} days ago`;
    return formatDate(dateString);
  };

  // Filter and sort users
  const getFilteredAndSortedUsers = () => {
    let filtered = users.filter(user => {
      const matchesSearch = user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.name.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesRole = roleFilter === 'All' || user.role === roleFilter;
      const matchesStatus = statusFilter === 'All' || user.status === statusFilter.toLowerCase();

      return matchesSearch && matchesRole && matchesStatus;
    });

    // Sort
    filtered.sort((a, b) => {
      let aVal, bVal;

      if (sortColumn === 'registrationDate' || sortColumn === 'lastLogin') {
        aVal = new Date(a[sortColumn]);
        bVal = new Date(b[sortColumn]);
      } else {
        aVal = a[sortColumn].toLowerCase();
        bVal = b[sortColumn].toLowerCase();
      }

      if (aVal < bVal) return sortDirection === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortDirection === 'asc' ? 1 : -1;
      return 0;
    });

    return filtered;
  };

  const filteredUsers = getFilteredAndSortedUsers();

  // Handle sort
  const handleSort = (column) => {
    if (sortColumn === column) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortColumn(column);
      setSortDirection('asc');
    }
  };

  // Get sort icon
  const getSortIcon = (column) => {
    if (sortColumn !== column) return <FaSort size={12} style={{ opacity: 0.3 }} />;
    return sortDirection === 'asc' ? <FaSortUp size={12} /> : <FaSortDown size={12} />;
  };

  // Toggle user status
  const handleDeactivateUser = () => {
    if (!selectedUser) return;

    setUsers(users.map(user =>
      user.id === selectedUser.id
        ? { ...user, status: user.status === 'active' ? 'inactive' : 'active' }
        : user
    ));

    setShowDeactivateModal(false);
    setSelectedUser(null);
  };

  // Reset password
  const handleResetPassword = () => {
    // In a real app, this would call an API
    setShowPasswordModal(false);
    setSelectedUser(null);
    alert(`Password reset email sent to ${selectedUser?.email}`);
  };

  // Export to CSV
  const handleExport = () => {
    const headers = ['Email', 'Name', 'Role', 'Department', 'Registration Date', 'Last Login', 'Status'];
    const csvData = filteredUsers.map(user => [
      user.email,
      user.name,
      user.role,
      user.department,
      formatDate(user.registrationDate),
      getRelativeTime(user.lastLogin),
      user.status.toUpperCase()
    ]);

    const csvContent = [
      headers.join(','),
      ...csvData.map(row => row.map(cell => `"${cell}"`).join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `users_export_${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  };

  // Card style
  const cardStyle = {
    background: 'white',
    borderRadius: '12px',
    padding: '1.75rem',
    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05), 0 10px 25px -5px rgba(0, 0, 0, 0.05)',
    border: '1px solid #f0f0f0'
  };

  const activeCount = users.filter(u => u.status === 'active').length;
  const inactiveCount = users.filter(u => u.status === 'inactive').length;

  return (
    <div>
      <Header title="User Management" />

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
        <div style={{ ...cardStyle, borderLeft: '4px solid var(--primary-color)' }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--gray-color)', marginBottom: '0.5rem', textTransform: 'uppercase', fontWeight: 600 }}>Total Users</div>
          <div style={{ fontSize: '2rem', fontWeight: 700 }}>{users.length}</div>
        </div>
        <div style={{ ...cardStyle, borderLeft: '4px solid #10b981' }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--gray-color)', marginBottom: '0.5rem', textTransform: 'uppercase', fontWeight: 600 }}>Active Users</div>
          <div style={{ fontSize: '2rem', fontWeight: 700 }}>{activeCount}</div>
        </div>
        <div style={{ ...cardStyle, borderLeft: '4px solid #ef4444' }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--gray-color)', marginBottom: '0.5rem', textTransform: 'uppercase', fontWeight: 600 }}>Inactive Users</div>
          <div style={{ fontSize: '2rem', fontWeight: 700 }}>{inactiveCount}</div>
        </div>
        <div style={{ ...cardStyle, borderLeft: '4px solid #3b82f6' }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--gray-color)', marginBottom: '0.5rem', textTransform: 'uppercase', fontWeight: 600 }}>Filtered Results</div>
          <div style={{ fontSize: '2rem', fontWeight: 700 }}>{filteredUsers.length}</div>
        </div>
      </div>

      {/* Main Table Card */}
      <div style={cardStyle}>
        {/* Filters and Search */}
        <div style={{ marginBottom: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <FaUsers /> Registered Users
            </h2>
            <button
              onClick={handleExport}
              style={{
                padding: '0.625rem 1.25rem',
                background: 'var(--primary-color)',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontWeight: 600,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                fontSize: '0.875rem',
                transition: 'all 0.2s'
              }}
              onMouseEnter={(e) => e.currentTarget.style.background = 'var(--primary-dark)'}
              onMouseLeave={(e) => e.currentTarget.style.background = 'var(--primary-color)'}
            >
              <FaDownload /> Export to CSV
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            {/* Search */}
            <div style={{ position: 'relative' }}>
              <FaSearch style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--gray-color)', fontSize: '0.875rem' }} />
              <input
                type="text"
                placeholder="Search by email or name..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  width: '100%',
                  padding: '0.625rem 0.75rem 0.625rem 2.5rem',
                  border: '1px solid var(--border-color)',
                  borderRadius: '8px',
                  fontSize: '0.875rem'
                }}
              />
            </div>

            {/* Role Filter */}
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              style={{
                padding: '0.625rem 0.75rem',
                border: '1px solid var(--border-color)',
                borderRadius: '8px',
                fontSize: '0.875rem',
                cursor: 'pointer'
              }}
            >
              <option value="All">All Roles</option>
              <option value="Admin">Admin</option>
              <option value="Manager">Manager</option>
              <option value="Staff">Staff</option>
              <option value="Viewer">Viewer</option>
            </select>

            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              style={{
                padding: '0.625rem 0.75rem',
                border: '1px solid var(--border-color)',
                borderRadius: '8px',
                fontSize: '0.875rem',
                cursor: 'pointer'
              }}
            >
              <option value="All">All Status</option>
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
            </select>

            {/* Filter Icon Button */}
            <button
              style={{
                padding: '0.625rem',
                border: '1px solid var(--border-color)',
                borderRadius: '8px',
                background: 'white',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.5rem',
                fontSize: '0.875rem',
                fontWeight: 600
              }}
            >
              <FaFilter /> Filters
            </button>
          </div>
        </div>

        {/* Table */}
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '2px solid var(--border-color)' }}>
                <th
                  onClick={() => handleSort('email')}
                  style={{
                    textAlign: 'left',
                    padding: '1rem',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    color: 'var(--gray-color)',
                    textTransform: 'uppercase',
                    cursor: 'pointer',
                    userSelect: 'none'
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    Email {getSortIcon('email')}
                  </div>
                </th>
                <th
                  onClick={() => handleSort('role')}
                  style={{
                    textAlign: 'left',
                    padding: '1rem',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    color: 'var(--gray-color)',
                    textTransform: 'uppercase',
                    cursor: 'pointer',
                    userSelect: 'none'
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    Role {getSortIcon('role')}
                  </div>
                </th>
                <th
                  onClick={() => handleSort('registrationDate')}
                  style={{
                    textAlign: 'left',
                    padding: '1rem',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    color: 'var(--gray-color)',
                    textTransform: 'uppercase',
                    cursor: 'pointer',
                    userSelect: 'none'
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    Registration {getSortIcon('registrationDate')}
                  </div>
                </th>
                <th
                  onClick={() => handleSort('lastLogin')}
                  style={{
                    textAlign: 'left',
                    padding: '1rem',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    color: 'var(--gray-color)',
                    textTransform: 'uppercase',
                    cursor: 'pointer',
                    userSelect: 'none'
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    Last Login {getSortIcon('lastLogin')}
                  </div>
                </th>
                <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.75rem', fontWeight: 700, color: 'var(--gray-color)', textTransform: 'uppercase' }}>
                  Status
                </th>
                <th style={{ textAlign: 'right', padding: '1rem', fontSize: '0.75rem', fontWeight: 700, color: 'var(--gray-color)', textTransform: 'uppercase' }}>
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '3rem', color: 'var(--gray-color)' }}>
                    <div style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '0.5rem' }}>No users found</div>
                    <div style={{ fontSize: '0.875rem' }}>Try adjusting your filters or search query</div>
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user, index) => (
                  <tr key={user.id} style={{ borderBottom: index === filteredUsers.length - 1 ? 'none' : '1px solid var(--border-color)' }}>
                    <td style={{ padding: '1rem' }}>
                      <div style={{ fontWeight: 600, marginBottom: '0.25rem' }}>{user.email}</div>
                      <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>{user.name}</div>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <span style={{
                        padding: '0.375rem 0.75rem',
                        borderRadius: '6px',
                        fontSize: '0.75rem',
                        fontWeight: 600,
                        background: roleColors[user.role].bg,
                        color: roleColors[user.role].color,
                        border: `1px solid ${roleColors[user.role].border}`,
                        display: 'inline-block'
                      }}>
                        {user.role}
                      </span>
                    </td>
                    <td style={{ padding: '1rem', fontSize: '0.875rem' }}>
                      {formatDate(user.registrationDate)}
                    </td>
                    <td style={{ padding: '1rem', fontSize: '0.875rem', color: 'var(--gray-color)' }}>
                      {getRelativeTime(user.lastLogin)}
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <span style={{
                        padding: '0.375rem 0.75rem',
                        borderRadius: '6px',
                        fontSize: '0.75rem',
                        fontWeight: 600,
                        background: user.status === 'active' ? '#d1fae5' : '#fee2e2',
                        color: user.status === 'active' ? '#065f46' : '#991b1b',
                        border: `1px solid ${user.status === 'active' ? '#10b981' : '#ef4444'}`,
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.375rem'
                      }}>
                        {user.status === 'active' ? <FaCheckCircle size={10} /> : <FaBan size={10} />}
                        {user.status.toUpperCase()}
                      </span>
                    </td>
                    <td style={{ padding: '1rem', textAlign: 'right' }}>
                      <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end', minWidth: '200px' }}>
                        <button
                          onClick={() => {
                            setSelectedUser(user);
                            setShowPasswordModal(true);
                          }}
                          style={{
                            padding: '0.5rem 0.75rem',
                            background: '#dbeafe',
                            color: '#1e40af',
                            border: '1px solid #3b82f6',
                            borderRadius: '6px',
                            fontSize: '0.75rem',
                            fontWeight: 600,
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.375rem',
                            transition: 'all 0.2s',
                            whiteSpace: 'nowrap',
                            width: '85px',
                            justifyContent: 'center'
                          }}
                          onMouseEnter={(e) => e.currentTarget.style.background = '#bfdbfe'}
                          onMouseLeave={(e) => e.currentTarget.style.background = '#dbeafe'}
                        >
                          <FaKey size={10} /> Reset
                        </button>
                        <button
                          onClick={() => {
                            setSelectedUser(user);
                            setShowDeactivateModal(true);
                          }}
                          style={{
                            padding: '0.5rem 0.75rem',
                            background: user.status === 'active' ? '#fee2e2' : '#d1fae5',
                            color: user.status === 'active' ? '#991b1b' : '#065f46',
                            border: `1px solid ${user.status === 'active' ? '#ef4444' : '#10b981'}`,
                            borderRadius: '6px',
                            fontSize: '0.75rem',
                            fontWeight: 600,
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.375rem',
                            transition: 'all 0.2s',
                            whiteSpace: 'nowrap',
                            width: '115px',
                            justifyContent: 'center'
                          }}
                          onMouseEnter={(e) => e.currentTarget.style.opacity = '0.8'}
                          onMouseLeave={(e) => e.currentTarget.style.opacity = '1'}
                        >
                          {user.status === 'active' ? <><FaBan size={10} /> Deactivate</> : <><FaCheckCircle size={10} /> Activate</>}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Footer */}
        {filteredUsers.length > 0 && (
          <div style={{ marginTop: '1.5rem', paddingTop: '1.5rem', borderTop: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>
              Showing {filteredUsers.length} of {users.length} users
            </div>
          </div>
        )}
      </div>

      {/* Deactivate Modal */}
      {showDeactivateModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }}>
          <div style={{
            background: 'white',
            borderRadius: '12px',
            padding: '2rem',
            maxWidth: '400px',
            width: '90%',
            boxShadow: '0 20px 50px rgba(0, 0, 0, 0.3)'
          }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1rem' }}>
              {selectedUser?.status === 'active' ? 'Deactivate User' : 'Activate User'}
            </h3>
            <p style={{ color: 'var(--gray-color)', marginBottom: '1.5rem' }}>
              {selectedUser?.status === 'active'
                ? `Are you sure you want to deactivate ${selectedUser?.email}? This will prevent them from logging in, but all their data will be preserved.`
                : `Are you sure you want to activate ${selectedUser?.email}? They will be able to log in again.`
              }
            </p>
            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <button
                onClick={() => {
                  setShowDeactivateModal(false);
                  setSelectedUser(null);
                }}
                style={{
                  padding: '0.625rem 1.25rem',
                  background: '#f3f4f6',
                  color: 'var(--dark-color)',
                  border: 'none',
                  borderRadius: '8px',
                  fontWeight: 600,
                  cursor: 'pointer'
                }}
              >
                Cancel
              </button>
              <button
                onClick={handleDeactivateUser}
                style={{
                  padding: '0.625rem 1.25rem',
                  background: selectedUser?.status === 'active' ? '#ef4444' : '#10b981',
                  color: 'white',
                  border: 'none',
                  borderRadius: '8px',
                  fontWeight: 600,
                  cursor: 'pointer'
                }}
              >
                {selectedUser?.status === 'active' ? 'Deactivate' : 'Activate'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Password Reset Modal */}
      {showPasswordModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }}>
          <div style={{
            background: 'white',
            borderRadius: '12px',
            padding: '2rem',
            maxWidth: '400px',
            width: '90%',
            boxShadow: '0 20px 50px rgba(0, 0, 0, 0.3)'
          }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1rem' }}>
              Reset Password
            </h3>
            <p style={{ color: 'var(--gray-color)', marginBottom: '1.5rem' }}>
              Send a password reset email to {selectedUser?.email}? They will receive instructions to create a new password.
            </p>
            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <button
                onClick={() => {
                  setShowPasswordModal(false);
                  setSelectedUser(null);
                }}
                style={{
                  padding: '0.625rem 1.25rem',
                  background: '#f3f4f6',
                  color: 'var(--dark-color)',
                  border: 'none',
                  borderRadius: '8px',
                  fontWeight: 600,
                  cursor: 'pointer'
                }}
              >
                Cancel
              </button>
              <button
                onClick={handleResetPassword}
                style={{
                  padding: '0.625rem 1.25rem',
                  background: '#3b82f6',
                  color: 'white',
                  border: 'none',
                  borderRadius: '8px',
                  fontWeight: 600,
                  cursor: 'pointer'
                }}
              >
                Send Reset Email
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserManagementPage;