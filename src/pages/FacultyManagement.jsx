import { useState } from 'react';
import Header from '../components/Header';
import FacultyTable from '../components/FacultyTable';
import FacultyForm from '../components/FacultyForm';
import { FaUserPlus } from 'react-icons/fa';

const FacultyManagement = () => {
  const [viewState, setViewState] = useState('list'); // list, add, edit
  const [selectedFaculty, setSelectedFaculty] = useState(null);
  const [facultyData, setFacultyData] = useState([
    {
      id: 1,
      name: 'Dr. Sarah Johnson',
      role: 'Head of Department',
      cabin: 'A-102',
      building: 'Science Block',
      floor: '1st Floor'
    },
    {
      id: 2,
      name: 'Prof. Michael Chen',
      role: 'Senior Lecturer',
      cabin: 'B-306',
      building: 'Engineering Wing',
      floor: '3rd Floor'
    },
    {
      id: 3,
      name: 'Dr. Elena Rodriguez',
      role: 'Research Lead',
      cabin: 'C-210',
      building: 'Arts Center',
      floor: '2nd Floor'
    },
    {
      id: 4,
      name: 'James Wilson',
      role: 'Lab Assistant',
      cabin: 'A-305',
      building: 'Science Block',
      floor: 'Ground Floor'
    }
  ]);

  const handleEdit = (faculty) => {
    setSelectedFaculty(faculty);
    setViewState('edit');
  };

  const handleDelete = (id) => {
    if (window.confirm('Are you sure you want to delete this faculty member?')) {
      setFacultyData(facultyData.filter(f => f.id !== id));
    }
  };

  const handleSave = (faculty) => {
    if (viewState === 'add') {
      setFacultyData([...facultyData, faculty]);
    } else {
      setFacultyData(facultyData.map(f => f.id === faculty.id ? faculty : f));
    }
    setViewState('list');
    setSelectedFaculty(null);
  };

  const stats = [
    { label: 'TOTAL FACULTY', value: facultyData.length, color: 'var(--primary-color)', bg: '#ecfccb' },
    { label: 'ASSIGNED CABINS', value: facultyData.filter(f => f.cabin).length, color: '#f59e0b', bg: '#fef3c7' },
    { label: 'ACTIVE BUILDINGS', value: new Set(facultyData.map(f => f.building)).size, color: '#64748b', bg: '#e2e8f0' }
  ];

  if (viewState === 'add' || viewState === 'edit') {
    return (
      <div>
        <Header title={viewState === 'add' ? "Add New Faculty" : "Edit Faculty"} />
        <FacultyForm
          faculty={selectedFaculty}
          onSave={handleSave}
          onCancel={() => { setViewState('list'); setSelectedFaculty(null); }}
        />
      </div>
    );
  }

  return (
    <div>
      <Header title="Faculty Management" />

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
        {stats.map((stat, index) => (
          <div key={index} className="card" style={{ padding: '1.5rem', background: 'white', borderRadius: '0.5rem', boxShadow: 'var(--shadow)', border: '1px solid var(--border-color)' }}>
            <div style={{ fontSize: '0.75rem', fontWeight: 600, letterSpacing: '0.05em', color: 'var(--muted-gray)', marginBottom: '0.5rem' }}>{stat.label}</div>
            <div style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--dark-color)' }}>{stat.value}</div>
            <div style={{ background: stat.bg, height: '4px', width: '100%', marginTop: '0.5rem', borderRadius: '2px' }}>
              <div style={{ background: stat.color, height: '100%', width: '70%', borderRadius: '2px' }}></div>
            </div>
          </div>
        ))}
      </div>

      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '1rem' }}>
        <button className="btn btn-primary" onClick={() => { setSelectedFaculty(null); setViewState('add'); }} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <FaUserPlus /> Add Faculty
        </button>
      </div>

      <FacultyTable
        facultyData={facultyData}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />
    </div>
  );
};

export default FacultyManagement;