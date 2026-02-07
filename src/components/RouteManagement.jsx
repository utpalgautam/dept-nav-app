// src/components/RouteManagement.jsx
const RouteManagement = () => {
  const routes = [
    { id: 1, name: 'Elevator to Lounge', distance: '22m', accessibility: 'Accessible', rt: '2045' },
    { id: 2, name: 'Stairs to Faculty', distance: '34m', accessibility: 'Public', rt: '2031' },
    { id: 3, name: 'Lab 202 to Lab 204', distance: '12m', accessibility: 'Restricted', rt: '2080' }
  ];

  return (
    <div style={{ display: 'flex', gap: '2rem', height: '600px' }}>
      <div style={{ flex: 2, backgroundColor: 'white', borderRadius: '0.5rem', padding: '1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
          <h3 style={{ fontWeight: '600' }}>Building 1</h3>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button className="btn btn-outline">+</button>
            <button className="btn btn-outline">-</button>
          </div>
        </div>
        
        <div style={{ 
          height: '400px', 
          backgroundColor: '#f8f9fa', 
          border: '1px solid var(--border-color)',
          borderRadius: '0.375rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: '1rem'
        }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '1.5rem', fontWeight: '600', color: 'var(--gray-color)' }}>Map View</div>
            <div style={{ color: 'var(--gray-color)' }}>Lm: 202</div>
            <div style={{ color: 'var(--gray-color)' }}>Bearing:</div>
          </div>
        </div>
      </div>
      
      <div style={{ flex: 1, backgroundColor: 'white', borderRadius: '0.5rem', padding: '1.5rem' }}>
        <h3 style={{ fontWeight: '600', marginBottom: '1rem' }}>Route Management</h3>
        <div style={{ backgroundColor: '#f3f4f6', padding: '1rem', borderRadius: '0.375rem', marginBottom: '1.5rem' }}>
          <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>EDITING</div>
          <div style={{ fontWeight: '600' }}>Entrance to Lab 202</div>
        </div>
        
        <div style={{ marginBottom: '1.5rem' }}>
          <div style={{ fontWeight: '500', marginBottom: '0.5rem' }}>START / END NODES</div>
          <div style={{ display: 'flex', gap: '1rem' }}>
            <div style={{ flex: 1 }}>
              <div className="form-control" style={{ textAlign: 'center' }}>Node_10</div>
            </div>
            <div style={{ flex: 1 }}>
              <div className="form-control" style={{ textAlign: 'center' }}>Node_44</div>
            </div>
          </div>
        </div>
        
        <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem' }}>
          <button className="btn btn-primary" style={{ flex: 1 }}>Save Path</button>
          <button className="btn btn-outline" style={{ flex: 1 }}>Save</button>
        </div>
        
        <div>
          <div style={{ fontWeight: '500', marginBottom: '1rem' }}>OTHER FLOOR ROUTES</div>
          {routes.map((route) => (
            <div key={route.id} style={{
              padding: '0.75rem',
              border: '1px solid var(--border-color)',
              borderRadius: '0.375rem',
              marginBottom: '0.5rem'
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ fontWeight: '500' }}>{route.name}</span>
                <span style={{ fontSize: '0.875rem' }}>{route.distance}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', color: 'var(--gray-color)' }}>
                <span>• {route.accessibility}</span>
                <span>RT: {route.rt}</span>
              </div>
            </div>
          ))}
        </div>
        
        <button className="btn btn-outline" style={{ width: '100%', marginTop: '1rem' }}>
          Export Manifest
        </button>
      </div>
    </div>
  );
};

export default RouteManagement;