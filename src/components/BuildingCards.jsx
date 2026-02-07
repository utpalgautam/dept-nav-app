// src/components/BuildingCards.jsx
import { FaEdit, FaUpload, FaEllipsisH } from 'react-icons/fa';

const BuildingCards = ({ buildings, onBuildingClick, onEdit, onUpload }) => {
  const getStatusColor = (status) => {
    switch (status) {
      case 'COMPLETE':
        return '#10b981';
      case 'IN PROGRESS':
        return '#f59e0b';
      default:
        return '#6b7280';
    }
  };

  return (
    <div className="buildings-grid">
      {buildings.map((building) => (
        <div
          key={building.id}
          className="building-card"
          style={{ padding: 0, overflow: 'hidden', cursor: 'pointer' }}
          onClick={() => onBuildingClick(building)}
        >
          <div style={{ height: '140px', background: '#e2e8f0', position: 'relative' }}>
            {/* Placeholder for building image */}
            <div style={{ position: 'absolute', top: '1rem', left: '1rem', background: 'white', padding: '0.25rem 0.5rem', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 700, boxShadow: '0 2px 4px rgba(0,0,0,0.1)' }}>
              {building.id === 1 ? 'BLDG-E1' : building.id === 2 ? 'BLDG-S4' : 'BLDG-L1'}
            </div>
            {building.status === 'IN PROGRESS' && (
              <div style={{ position: 'absolute', bottom: '0.5rem', right: '0.5rem', background: '#e11d48', color: 'white', padding: '0.25rem 0.5rem', fontSize: '0.65rem', fontWeight: 700, borderRadius: '2px' }}>
                MISSING MAPS
              </div>
            )}
          </div>
          <div style={{ padding: '1.5rem' }}>
            <div className="building-header" style={{ marginBottom: '0.5rem' }}>
              <div>
                <div className="building-title">{building.name}</div>
                <div className="building-subtitle">{building.department}</div>
              </div>
              <FaEllipsisH style={{ color: 'var(--muted-gray)', cursor: 'pointer' }} />
            </div>

            <div className="building-stats" style={{ background: '#f8fafc', padding: '1rem', borderRadius: '0.5rem', justifyContent: 'space-between' }}>
              <div className="building-stat">
                <span className="stat-label">FLOORS</span>
                <span className="stat-value">{building.floors}</span>
              </div>
              <div className="building-stat">
                <span className="stat-label">STATUS</span>
                <span className="stat-value" style={{ color: getStatusColor(building.status) }}>
                  {building.status}
                </span>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '1rem', marginTop: '1.25rem' }}>
              <button
                className="btn btn-outline"
                style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', fontSize: '0.8rem' }}
                onClick={(e) => { e.stopPropagation(); onEdit(building); }}
              >
                <FaEdit /> Edit
              </button>
              <button
                className="btn btn-primary"
                style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', fontSize: '0.8rem', background: '#bef264', color: '#1a2e05' }}
                onClick={(e) => { e.stopPropagation(); onUpload(building); }}
              >
                <FaUpload /> Upload
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default BuildingCards;