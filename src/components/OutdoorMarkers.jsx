// src/components/OutdoorMarkers.jsx
import { FaSearch } from 'react-icons/fa';

const OutdoorMarkers = () => {
  const markers = [
    {
      id: 1,
      name: 'Engineering Block A',
      category: 'FACULTY OF SCIENCE',
      coordinates: '49.712, -74.000'
    },
    {
      id: 2,
      name: 'Main Library',
      category: 'SERVICES'
    },
    {
      id: 3,
      name: 'Memorial Gardens',
      category: 'LEISURE'
    },
    {
      id: 4,
      name: 'Sports Complex',
      category: 'ATHLETICS'
    }
  ];

  return (
    <div style={{ display: 'flex', gap: '2rem' }}>
      <div style={{ flex: 1 }}>
        <div style={{ position: 'relative', marginBottom: '1rem' }}>
          <FaSearch style={{ position: 'absolute', left: '0.75rem', top: '0.75rem', color: 'var(--gray-color)' }} />
          <input 
            type="text" 
            placeholder="Find a building..." 
            className="form-control" 
            style={{ paddingLeft: '2.5rem' }}
          />
        </div>
        
        <div style={{ 
          backgroundColor: 'white', 
          borderRadius: '0.5rem', 
          border: '1px solid var(--border-color)',
          padding: '1rem'
        }}>
          <h4 style={{ fontWeight: '600', marginBottom: '1rem' }}>Buildings</h4>
          {markers.map((marker) => (
            <div key={marker.id} style={{
              padding: '0.75rem',
              borderBottom: '1px solid var(--border-color)',
              cursor: 'pointer'
            }}>
              <div style={{ fontWeight: '500' }}>{marker.name}</div>
              <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>{marker.category}</div>
              {marker.coordinates && (
                <div style={{ fontSize: '0.75rem', color: 'var(--gray-color)' }}>{marker.coordinates}</div>
              )}
            </div>
          ))}
          
          <div style={{ paddingTop: '1rem' }}>
            <button className="btn btn-primary" style={{ width: '100%' }}>Add New Marker</button>
          </div>
        </div>
      </div>
      
      <div style={{ flex: 2, backgroundColor: 'white', borderRadius: '0.5rem', padding: '1.5rem' }}>
        <h3 style={{ fontWeight: '600', marginBottom: '1.5rem' }}>Edit Marker</h3>
        
        <div style={{ backgroundColor: '#f3f4f6', padding: '1rem', borderRadius: '0.375rem', marginBottom: '1.5rem' }}>
          <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>MARKER DETAILS</div>
        </div>
        
        <div className="form-group">
          <label>Name</label>
          <input type="text" className="form-control" defaultValue="Engineering Block A" />
        </div>
        
        <div className="form-group">
          <label>Category</label>
          <select className="form-control">
            <option>Academic Building</option>
            <option>Administrative Building</option>
            <option>Recreational Area</option>
            <option>Sports Facility</option>
          </select>
        </div>
        
        <div className="form-group">
          <label>COORDINATES</label>
          <div style={{ display: 'flex', gap: '1rem' }}>
            <div style={{ flex: 1 }}>
              <label style={{ fontSize: '0.875rem' }}>LAT</label>
              <input type="text" className="form-control" defaultValue="40.7128" />
            </div>
            <div style={{ flex: 1 }}>
              <label style={{ fontSize: '0.875rem' }}>LNG</label>
              <input type="text" className="form-control" defaultValue="-74.0060" />
            </div>
          </div>
        </div>
        
        <div className="form-group">
          <label>DESCRIPTION</label>
          <textarea 
            className="form-control" 
            rows="4"
            defaultValue="Primary academic building for the Faculty of Engineering, housing advanced laboratories for Civil and Mechanical departments."
          />
        </div>
        
        <div className="form-group">
          <label>INDOOR CONNECTIONS</label>
          <select className="form-control">
            <option>Link Indoor Floor Plan</option>
            <option>Associate with building levels</option>
          </select>
        </div>
        
        <button className="btn btn-primary" style={{ width: '100%' }}>Save Marker</button>
      </div>
    </div>
  );
};

export default OutdoorMarkers;