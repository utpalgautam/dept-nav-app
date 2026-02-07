import { useState } from 'react';
import { FaEdit, FaTrash } from 'react-icons/fa';

const FacultyTable = ({ facultyData, onEdit, onDelete }) => {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredData = facultyData.filter(faculty =>
    faculty.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    faculty.cabin.toLowerCase().includes(searchTerm.toLowerCase()) ||
    faculty.building.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="table-container" style={{ border: 'none', boxShadow: 'none', background: 'transparent', padding: 0 }}>
      <div className="table-header" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
        <input
          type="text"
          placeholder="Search by name, cabin, or building..."
          className="form-control"
          style={{ width: 400, background: 'white' }}
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      <div className="card" style={{ padding: '0', background: 'white', borderRadius: '0.5rem', boxShadow: 'var(--shadow)', border: '1px solid var(--border-color)', overflow: 'hidden' }}>
        <table className="table" style={{ width: '100%' }}>
          <thead style={{ background: '#f8fafc' }}>
            <tr>
              <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>FACULTY NAME</th>
              <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>CABIN NO.</th>
              <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>BUILDING</th>
              <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>FLOOR</th>
              <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>ACTIONS</th>
            </tr>
          </thead>
          <tbody>
            {filteredData.map((faculty) => (
              <tr key={faculty.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                <td style={{ padding: '1rem 1.5rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#ecfccb', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.75rem', fontWeight: 700, color: '#3f6212' }}>
                      {faculty.name.split(' ').map(n => n[0]).join('').substring(0, 2)}
                    </div>
                    <div>
                      <div className="font-medium" style={{ fontWeight: 600, color: 'var(--dark-color)' }}>{faculty.name}</div>
                      <div className="text-sm text-gray-500" style={{ fontSize: '0.8rem' }}>{faculty.role}</div>
                    </div>
                  </div>
                </td>
                <td style={{ padding: '1rem 1.5rem', fontWeight: 600 }}>{faculty.cabin}</td>
                <td style={{ padding: '1rem 1.5rem' }}>{faculty.building}</td>
                <td style={{ padding: '1rem 1.5rem', fontWeight: 600 }}>{faculty.floor}</td>
                <td style={{ padding: '1rem 1.5rem' }}>
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <button className="btn" style={{ padding: '0.25rem', color: 'var(--muted-gray)' }} onClick={() => onEdit(faculty)}>
                      <FaEdit />
                    </button>
                    <button className="btn" style={{ padding: '0.25rem', color: 'var(--muted-gray)' }} onClick={() => onDelete(faculty.id)}>
                      <FaTrash />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div style={{ padding: '1rem', textAlign: 'center', color: 'var(--gray-color)', borderTop: '1px solid var(--border-color)', fontSize: '0.875rem' }}>
          Showing {filteredData.length} of {facultyData.length} records
        </div>
      </div>
    </div>
  );
};

export default FacultyTable;