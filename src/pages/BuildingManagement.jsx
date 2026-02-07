// src/pages/BuildingManagement.jsx
import { useState } from 'react';
import { FaPlus } from 'react-icons/fa';
import Header from '../components/Header';
import BuildingCards from '../components/BuildingCards';
import BuildingDetails from '../components/BuildingDetails';
import BuildingForm from '../components/BuildingForm';

const BuildingManagement = () => {
  const [viewState, setViewState] = useState('list'); // list, details, add, edit
  const [selectedBuilding, setSelectedBuilding] = useState(null);
  const [buildings, setBuildings] = useState([
    {
      id: 1,
      name: 'Engineering Hall',
      department: 'Faculty of Applied Sciences',
      floors: '05',
      status: 'COMPLETE',
      maps: '5/5'
    },
    {
      id: 2,
      name: 'Science Center',
      department: 'Life Sciences Department',
      floors: '04',
      status: 'IN PROGRESS',
      maps: '3/4'
    },
    {
      id: 3,
      name: 'Main Library',
      department: 'Multi-Faculty Resource Center',
      floors: '08',
      status: 'COMPLETE',
      maps: '8/8'
    }
  ]);

  const handleBuildingClick = (building) => {
    setSelectedBuilding(building);
    setViewState('details');
  };

  const handleAddBuilding = () => {
    setSelectedBuilding(null);
    setViewState('add');
  };

  const handleEditBuilding = (building) => {
    setSelectedBuilding(building);
    setViewState('edit');
  };

  const handleSaveBuilding = (buildingData) => {
    if (viewState === 'add') {
      const newBuilding = {
        ...buildingData,
        id: buildings.length + 1,
        maps: '0/' + buildingData.floors
      };
      setBuildings([...buildings, newBuilding]);
    } else if (viewState === 'edit') {
      setBuildings(buildings.map(b => b.id === buildingData.id ? buildingData : b));
    }
    setViewState('list');
    setSelectedBuilding(null);
  };

  const handleCancel = () => {
    setViewState('list');
    setSelectedBuilding(null);
  };

  const handleBackToDirectory = () => {
    setViewState('list');
    setSelectedBuilding(null);
  };

  if (viewState === 'details' && selectedBuilding) {
    return (
      <div>
        <Header title="Building & Floor Maps" />
        <BuildingDetails building={selectedBuilding} onBack={handleBackToDirectory} />
      </div>
    );
  }

  if (viewState === 'add' || viewState === 'edit') {
    return (
      <div>
        <Header title={viewState === 'add' ? "Add New Building" : "Edit Building"} />
        <BuildingForm
          building={selectedBuilding}
          onSave={handleSaveBuilding}
          onCancel={handleCancel}
        />
      </div>
    );
  }

  return (
    <div>
      <Header title="Building Directory" />

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <p style={{ color: 'var(--gray-color)', margin: 0 }}>
          Manage your departmental physical space. Map floor plans, set points of interest,
          and configure routing paths across all campus facilities.
        </p>
        <button onClick={handleAddBuilding} className="btn btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 600 }}>
          <FaPlus /> Add New Building
        </button>
      </div>

      <BuildingCards
        buildings={buildings}
        onBuildingClick={handleBuildingClick}
        onEdit={handleEditBuilding}
      />
    </div>
  );
};

export default BuildingManagement;