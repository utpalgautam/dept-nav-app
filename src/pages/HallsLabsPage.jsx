import { useState } from 'react';
import Header from '../components/Header';
import HallsLabsDirectory from '../components/HallsLabsDirectory';
import HallsLabsForm from '../components/HallsLabsForm';

const HallsLabsPage = () => {
  const [viewState, setViewState] = useState('list'); // list, add, edit
  const [selectedItem, setSelectedItem] = useState(null);
  const [hallsData, setHallsData] = useState([
    {
      id: 1,
      name: 'Lab 202',
      type: 'LABORATORY',
      building: 'Engineering Block A',
      floor: '2nd Floor',
      capacity: 45,
      status: 'ACTIVE'
    },
    {
      id: 2,
      name: 'Lab 204',
      type: 'LABORATORY',
      building: 'Engineering Block A',
      floor: '2nd Floor',
      capacity: 38,
      status: 'ACTIVE'
    },
    {
      id: 3,
      name: 'Hall A',
      type: 'LECTURE HALL',
      building: 'Science Building',
      floor: '1st Floor',
      capacity: 150,
      status: 'ACTIVE'
    },
    {
      id: 4,
      name: 'Hall B',
      type: 'LECTURE HALL',
      building: 'Science Building',
      floor: '1st Floor',
      capacity: 120,
      status: 'MAINTENANCE'
    },
    {
      id: 5,
      name: 'Computer Lab 101',
      type: 'LABORATORY',
      building: 'IT Building',
      floor: 'Ground Floor',
      capacity: 50,
      status: 'ACTIVE'
    }
  ]);

  const handleAdd = () => {
    setSelectedItem(null);
    setViewState('add');
  };

  const handleEdit = (item) => {
    setSelectedItem(item);
    setViewState('edit');
  };

  const handleDelete = (id) => {
    if (window.confirm('Are you sure you want to delete this hall/lab?')) {
      setHallsData(hallsData.filter(item => item.id !== id));
    }
  };

  const handleSave = (item) => {
    if (viewState === 'add') {
      setHallsData([...hallsData, item]);
    } else {
      setHallsData(hallsData.map(h => h.id === item.id ? item : h));
    }
    setViewState('list');
    setSelectedItem(null);
  };

  const handleCancel = () => {
    setViewState('list');
    setSelectedItem(null);
  };

  if (viewState === 'add' || viewState === 'edit') {
    return (
      <div>
        <Header title={viewState === 'add' ? "Add New Hall/Lab" : "Edit Hall/Lab"} />
        <HallsLabsForm
          item={selectedItem}
          onSave={handleSave}
          onCancel={handleCancel}
        />
      </div>
    );
  }

  return (
    <div>
      <Header title="Halls & Labs Directory" />
      <HallsLabsDirectory
        hallsData={hallsData}
        onAdd={handleAdd}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />
    </div>
  );
};

export default HallsLabsPage;