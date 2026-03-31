import { useState } from 'react';
import { FaTrash } from 'react-icons/fa';

const HallsLabsDirectory = ({ processedData, buildings = [], onAdd, onEdit, onDelete, sortAsc, onSortToggle }) => {
  const getAvatarIcon = (category) => {
    if (category === 'LAB') {
      return (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M10 2v7.31"></path>
          <path d="M14 9.3V1.99"></path>
          <path d="M8.5 2h7"></path>
          <path d="M14 9.3a6.5 6.5 0 1 1-4 0"></path>
          <path d="M5.52 16h12.96"></path>
        </svg>
      );
    }
    return (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect x="4" y="2" width="16" height="20" rx="2" ry="2"></rect>
        <path d="M9 22v-4h6v4"></path>
        <path d="M8 6h.01"></path>
        <path d="M16 6h.01"></path>
        <path d="M12 6h.01"></path>
        <path d="M12 10h.01"></path>
        <path d="M12 14h.01"></path>
        <path d="M16 10h.01"></path>
        <path d="M16 14h.01"></path>
        <path d="M8 10h.01"></path>
        <path d="M8 14h.01"></path>
      </svg>
    );
  };

  const getBuildingName = (id) => buildings.find(b => b.id === id)?.name || id;

  const getLocationString = (bldg, floor, roomNumber) => {
    const parts = [];
    if (bldg) parts.push(`${getBuildingName(bldg)}`);
    if (floor !== undefined && floor !== '') parts.push(`Floor ${floor}`);
    if (roomNumber) parts.push(`${roomNumber}`);
    return parts.join(', ') || 'Location Pending';
  };

  return (
    <div>
      <div className="hl-toolbar">
        <button className="hl-btn-sort" onClick={onSortToggle}>
          Sort {sortAsc ? '↓' : '↑'}
        </button>
        <button className="hl-btn-green" onClick={onAdd}>
          + Add Hall/Lab
        </button>
      </div>

      <div className="hl-table-container">
        <div className="hl-table-header">
          <span style={{ paddingLeft: '4rem' }}>Room Name</span>
          <span style={{ textAlign: 'center' }}>Location</span>
          <span style={{ paddingLeft: '1.5rem' }}>Type</span>
          <span style={{ textAlign: 'center' }}>Action</span>
        </div>

        {processedData.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '3rem', color: '#6b7280' }}>
            No halls or labs found.
          </div>
        ) : (
          processedData.map((item) => (
            <div key={item.id} className="hl-table-row">
              <div className="hl-table-cell hl-cell-room">
                {item.imageUrl ? (
                  <img src={item.imageUrl} alt="" className="hl-avatar" />
                ) : (
                  <div className="hl-avatar">
                    {getAvatarIcon(item.category)}
                  </div>
                )}
                <div>
                  <div className="hl-cell-strong">{item.name}</div>
                  <div style={{ fontSize: '0.9rem', color: '#9aa4af', marginTop: '0.2rem' }}>
                    {item.category === 'LAB' ? item.department || 'Lab' : item.contactPerson || 'Hall'}
                  </div>
                </div>
              </div>

              <div className="hl-table-cell" style={{ justifyContent: 'center' }}>
                {getLocationString(item.building, item.floor, item.roomNumber)}
              </div>

              <div className="hl-table-cell">
                <span style={{
                  padding: '0.4rem 0.8rem',
                  borderRadius: '999px',
                  background: '#D6EDD9',
                  color: '#111',
                  fontSize: '0.8rem',
                  fontWeight: '500'
                }}>
                  {item.category === 'LAB' ? 'Laboratory' : (item.type || 'Hall')}
                </span>
              </div>

              <div className="hl-table-cell" style={{ display: 'flex', gap: '0.8rem', justifyContent: 'center' }}>
                <button className="hl-action-pill" onClick={(e) => { e.stopPropagation(); onEdit(item); }}>
                  Modify
                </button>
                <button className="hl-action-icon" onClick={(e) => { e.stopPropagation(); onDelete(item); }}>
                  <FaTrash size={16} />
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default HallsLabsDirectory;
