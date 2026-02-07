// src/components/UserManagement.jsx
const UserManagement = () => {
  const users = [
    {
      id: 1,
      initials: 'JD',
      name: 'Jane Cooper',
      email: 'jane.cooper@university.edu',
      role: 'FULL SYSTEM ACCESS',
      status: 'ACTIVE',
      lastActivity: '2 hours ago',
      daysLeft: '90 DAYS LEFT'
    },
    {
      id: 2,
      initials: 'TH',
      name: 'Tom Hiddleston',
      email: 't.hiddleston@faculty.edu',
      role: 'FACULTY ADMIN',
      department: 'Admin & Facilities',
      status: 'ACTIVE',
      lastActivity: 'Yesterday',
      daysLeft: '92 DAYS LEFT'
    },
    {
      id: 3,
      initials: 'SK',
      name: 'Sarah Kerrigan',
      email: 'sarah.k.kerrigan@campus-ops.org',
      role: 'BUILDING MANAGER',
      department: 'Engineering Block A',
      status: 'INACTIVE',
      lastActivity: '3 days ago',
      daysLeft: '00:04:12'
    }
  ];

  return (
    <div className="table-container">
      <div className="table-header">
        <h2>User Management</h2>
        <input type="text" placeholder="Search by name, email or role..." className="search-box" />
      </div>

      <div className="stats-row" style={{ display: 'flex', gap: '2rem', marginBottom: '1.5rem' }}>
        <div>
          <div className="text-sm text-gray-500">TOTALS</div>
          <div className="text-2xl font-bold">1,284</div>
        </div>
        <div>
          <div className="text-sm text-gray-500">ACTIVE NOW</div>
          <div className="text-2xl font-bold">42</div>
        </div>
        <div>
          <div className="text-sm text-gray-500">SUPER ADMINS</div>
          <div className="text-2xl font-bold">6</div>
        </div>
        <div>
          <div className="text-sm text-gray-500">PENDING</div>
          <div className="text-2xl font-bold">12</div>
        </div>
      </div>

      <div className="user-list">
        {users.map((user) => (
          <div key={user.id} className="user-card" style={{
            display: 'flex',
            alignItems: 'center',
            padding: '1rem',
            border: '1px solid var(--border-color)',
            borderRadius: '0.5rem',
            marginBottom: '1rem',
            backgroundColor: 'white'
          }}>
            <div style={{
              width: '48px',
              height: '48px',
              borderRadius: '50%',
              backgroundColor: '#3b82f6',
              color: 'white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 'bold',
              marginRight: '1rem'
            }}>
              {user.initials}
            </div>
            
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: '600' }}>{user.name}</div>
                  <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>{user.email}</div>
                  <div style={{ fontSize: '0.875rem', fontWeight: '500' }}>{user.role}</div>
                  {user.department && (
                    <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>{user.department}</div>
                  )}
                </div>
                
                <div style={{ textAlign: 'right' }}>
                  <span className={`status-badge ${user.status === 'ACTIVE' ? 'status-available' : ''}`}>
                    {user.status}
                  </span>
                  <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginTop: '0.25rem' }}>
                    {user.lastActivity}
                  </div>
                  <div style={{ fontSize: '0.875rem', fontWeight: '500' }}>{user.daysLeft}</div>
                </div>
              </div>
              
              <div style={{ marginTop: '1rem', display: 'flex', gap: '1rem' }}>
                <div className="form-check">
                  <input type="checkbox" id={`indoor-${user.id}`} className="form-check-input" />
                  <label htmlFor={`indoor-${user.id}`} className="form-check-label">Indoor Map Editing</label>
                </div>
                <div className="form-check">
                  <input type="checkbox" id={`routing-${user.id}`} className="form-check-input" />
                  <label htmlFor={`routing-${user.id}`} className="form-check-label">Routing Path Config</label>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
      
      <div style={{ marginTop: '1rem', textAlign: 'center', color: 'var(--gray-color)' }}>
        Showing 1 - 10 of 1,284 users
      </div>
    </div>
  );
};

export default UserManagement;