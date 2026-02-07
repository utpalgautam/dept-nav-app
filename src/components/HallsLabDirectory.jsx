// src/components/HallsLabsDirectory.jsx
const HallsLabsDirectory = () => {
  const facilities = [
    {
      id: 1,
      name: 'Physics Lab A',
      category: 'LAB',
      location: 'Bldg 1, Floor 2',
      faculty: 'Science',
      status: 'Active'
    },
    {
      id: 2,
      name: 'Main Lecture Hall',
      category: 'HALL',
      location: 'Bldg 3, Floor 1',
      faculty: 'Arts',
      status: 'Active'
    },
    {
      id: 3,
      name: 'Chemistry Lab 04',
      category: 'LAB',
      location: 'Bldg 5, Floor 3',
      faculty: 'Science',
      status: 'Maintenance'
    },
    {
      id: 4,
      name: 'Seminar Room 12',
      category: 'HALL',
      location: 'Bldg 5, Floor 1',
      faculty: 'Engineering',
      status: 'Active'
    },
    {
      id: 5,
      name: 'Bio-Research Hub',
      category: 'LAB',
      location: 'Bldg 2, Floor G',
      faculty: 'Medicine',
      status: 'Closed'
    }
  ];

  const getStatusColor = (status) => {
    switch(status) {
      case 'Active':
        return '#10b981';
      case 'Maintenance':
        return '#f59e0b';
      case 'Closed':
        return '#ef4444';
      default:
        return '#6b7280';
    }
  };

  return (
    <div>
      <div className="stats-grid" style={{ marginBottom: '2rem' }}>
        <div className="stat-card">
          <h3>Total Halls</h3>
          <div className="stat-number">124</div>
        </div>
        <div className="stat-card">
          <h3>Total Labs</h3>
          <div className="stat-number">86</div>
        </div>
        <div className="stat-card">
          <h3>Maintenance</h3>
          <div className="stat-number">12</div>
        </div>
        <div className="stat-card">
          <h3>Available Now</h3>
          <div className="stat-number">198</div>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '2rem' }}>
        <div style={{ flex: 2 }}>
          <div className="table-container">
            <div className="table-header">
              <h3>Showing 210 facilities</h3>
            </div>
            
            <table className="table">
              <thead>
                <tr>
                  <th>FACILITY NAME</th>
                  <th>CATEGORY</th>
                  <th>LOCATION</th>
                  <th>FACULTY</th>
                  <th>STATUS</th>
                </tr>
              </thead>
              <tbody>
                {facilities.map((facility) => (
                  <tr key={facility.id}>
                    <td style={{ fontWeight: '500' }}>{facility.name}</td>
                    <td>{facility.category}</td>
                    <td>{facility.location}</td>
                    <td>{facility.faculty}</td>
                    <td>
                      <span style={{ 
                        color: getStatusColor(facility.status),
                        fontWeight: '500'
                      }}>
                        {facility.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            
            <div style={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              alignItems: 'center',
              marginTop: '1rem'
            }}>
              <button className="btn btn-primary">Add Facility</button>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button className="btn btn-outline">Previous</button>
                <button className="btn btn-outline">1</button>
                <button className="btn btn-outline">2</button>
                <button className="btn btn-outline">3</button>
                <span>...</span>
                <button className="btn btn-outline">12</button>
                <button className="btn btn-outline">Next</button>
              </div>
            </div>
          </div>
        </div>
        
        <div style={{ flex: 1 }}>
          <div className="table-container">
            <h3 style={{ marginBottom: '1rem' }}>Quick Preview</h3>
            <div style={{ 
              height: '200px', 
              backgroundColor: '#f8f9fa', 
              borderRadius: '0.375rem',
              marginBottom: '1.5rem',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              <div style={{ textAlign: 'center', color: 'var(--gray-color)' }}>
                FLOOR MAP VIEW
              </div>
            </div>
            
            <div style={{ marginBottom: '1.5rem' }}>
              <h4 style={{ fontSize: '0.875rem', fontWeight: '600', marginBottom: '0.5rem' }}>UPCOMING BOOKINGS</h4>
              <div style={{ 
                backgroundColor: '#f3f4f6', 
                padding: '0.75rem', 
                borderRadius: '0.375rem',
                marginBottom: '0.5rem'
              }}>
                <div style={{ fontWeight: '500' }}>Advanced Physics 101</div>
                <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>09:00 AM - 11:00 AM</div>
              </div>
              <div style={{ 
                backgroundColor: '#f3f4f6', 
                padding: '0.75rem', 
                borderRadius: '0.375rem'
              }}>
                <div style={{ fontWeight: '500' }}>Research Seminar</div>
                <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>01:30 PM - 03:00 PM</div>
              </div>
            </div>
            
            <div>
              <h4 style={{ fontSize: '0.875rem', fontWeight: '600', marginBottom: '0.5rem' }}>EQUIPMENT LIST</h4>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                <span style={{ 
                  backgroundColor: '#e5e7eb', 
                  padding: '0.25rem 0.75rem', 
                  borderRadius: '9999px',
                  fontSize: '0.875rem'
                }}>
                  Seat Board
                </span>
                <span style={{ 
                  backgroundColor: '#e5e7eb', 
                  padding: '0.25rem 0.75rem', 
                  borderRadius: '9999px',
                  fontSize: '0.875rem'
                }}>
                  Oscilloscope
                </span>
                <span style={{ 
                  backgroundColor: '#e5e7eb', 
                  padding: '0.25rem 0.75rem', 
                  borderRadius: '9999px',
                  fontSize: '0.875 rem'
                }}>
                  Printer x2  
                </span>
                 </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
export default HallsLabsDirectory;