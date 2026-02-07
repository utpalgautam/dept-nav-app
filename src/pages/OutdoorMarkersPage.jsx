// src/pages/OutdoorMarkersPage.jsx
import Header from '../components/Header';
import OutdoorMarkers from '../components/OutdoorMarkers';

const OutdoorMarkersPage = () => {
  return (
    <div>
      <Header title="Outdoor Markers" />
      <p style={{ marginBottom: '1.5rem', color: 'var(--gray-color)' }}>
        Configure campus locations
      </p>
      <OutdoorMarkers />
    </div>
  );
};

export default OutdoorMarkersPage;