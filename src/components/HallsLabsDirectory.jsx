import { useState } from 'react';
import { FaSearch, FaEdit, FaTrash } from 'react-icons/fa';

const HallsLabsDirectory = ({ hallsData, onAdd, onEdit, onDelete }) => {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredData = hallsData.filter(item =>
    item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.building.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.type.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div style={{ display: 'flex', gap: '2rem', flexDirection: 'column' }}>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '0.5rem',
        border: '1px solid var(--border-color)',
        padding: '1.5rem'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
          <h2 style={{ fontWeight: '600' }}>Halls & Labs Directory</h2>
          <button className="btn btn-primary" onClick={onAdd}>+ Add Hall/Lab</button>
        </div>

        <div style={{ position: 'relative', marginBottom: '1.5rem' }}>
          <FaSearch style={{ position: 'absolute', left: '0.75rem', top: '0.75rem', color: 'var(--gray-color)' }} />
          <input
            type="text"
            placeholder="Search by name, building, or type..."
            className="form-control"
            style={{ paddingLeft: '2.5rem' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '2px solid var(--border-color)' }}>
                <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: 'var(--gray-color)' }}>Name</th>
                <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: 'var(--gray-color)' }}>Type</th>
                <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: 'var(--gray-color)' }}>Building</th>
                <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: 'var(--gray-color)' }}>Floor</th>
                <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: 'var(--gray-color)' }}>Capacity</th>
                <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: 'var(--gray-color)' }}>Status</th>
                <th style={{ padding: '1rem', textAlign: 'center', fontWeight: '600', color: 'var(--gray-color)' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredData.map((item) => (
                <tr key={item.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <td style={{ padding: '1rem', fontWeight: '500' }}>{item.name}</td>
                  <td style={{ padding: '1rem', fontSize: '0.875rem', color: 'var(--gray-color)' }}>{item.type}</td>
                  <td style={{ padding: '1rem', fontSize: '0.875rem' }}>{item.building}</td>
                  <td style={{ padding: '1rem', fontSize: '0.875rem' }}>{item.floor}</td>
                  <td style={{ padding: '1rem', fontSize: '0.875rem' }}>{item.capacity} seats</td>
                  <td style={{ padding: '1rem' }}>
                    <span style={{
                      padding: '0.375rem 0.75rem',
                      borderRadius: '0.25rem',
                      fontSize: '0.75rem',
                      fontWeight: '600',
                      backgroundColor: item.status === 'ACTIVE' ? '#d1fae5' : '#fef3c7',
                      color: item.status === 'ACTIVE' ? '#065f46' : '#92400e'
                    }}>
                      {item.status}
                    </span>
                  </td>
                  <td style={{ padding: '1rem', textAlign: 'center' }}>
                    <button
                      onClick={() => onEdit(item)}
                      style={{
                        background: 'none',
                        border: 'none',
                        cursor: 'pointer',
                        color: 'var(--primary-color)',
                        marginRight: '0.5rem'
                      }}
                    >
                      <FaEdit />
                    </button>
                    <button
                      onClick={() => onDelete(item.id)}
                      style={{
                        background: 'none',
                        border: 'none',
                        cursor: 'pointer',
                        color: '#ef4444'
                      }}
                    >
                      <FaTrash />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div style={{ padding: '1rem', textAlign: 'center', color: 'var(--gray-color)', fontSize: '0.875rem' }}>
          Showing {filteredData.length} of {hallsData.length} records
        </div>
      </div>
    </div>
  );
};

export default HallsLabsDirectory;
