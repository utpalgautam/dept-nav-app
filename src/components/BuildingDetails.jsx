import { useState } from 'react';
import { FaPlus, FaPencilAlt, FaUpload, FaMap, FaLayerGroup, FaArrowLeft } from 'react-icons/fa';
import FloorForm from './FloorForm';

const BuildingDetails = ({ building, onBack }) => {
    const [floors, setFloors] = useState([
        { id: 1, name: 'Floor 1 (Ground)', description: 'Admin Offices, Main Lobby, Cafeteria', status: 'MAP ACTIVE', mapActive: true },
        { id: 2, name: 'Floor 2', description: 'Computer Labs, Research Wings', status: 'MAP REQUIRED', mapActive: false }
    ]);
    const [viewState, setViewState] = useState('list'); // list, add_floor, edit_floor
    const [selectedFloor, setSelectedFloor] = useState(null);

    const [previewFloor, setPreviewFloor] = useState(null);

    if (!building) return null;

    const handleAddFloor = () => {
        setSelectedFloor(null);
        setViewState('add_floor');
    };

    const handleEditFloor = (floor) => {
        setSelectedFloor(floor);
        setViewState('edit_floor');
    };

    const handleSaveFloor = (floorData) => {
        if (viewState === 'add_floor') {
            setFloors([...floors, { ...floorData, id: floors.length + 1 }]);
        } else if (viewState === 'edit_floor') {
            setFloors(floors.map(f => f.id === floorData.id ? floorData : f));
        }
        setViewState('list');
        setSelectedFloor(null);
    };

    const handleCancel = () => {
        setViewState('list');
        setSelectedFloor(null);
    };

    if (viewState === 'add_floor' || viewState === 'edit_floor') {
        return (
            <FloorForm
                floor={selectedFloor}
                onSave={handleSaveFloor}
                onCancel={handleCancel}
            />
        );
    }

    return (
        <div className="building-details">
            {/* Header */}
            <div style={{ marginBottom: '2rem' }}>
                <button
                    onClick={onBack}
                    className="btn btn-outline"
                    style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem', padding: '0.5rem 1rem' }}
                >
                    <FaArrowLeft /> Back to Directory
                </button>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h2 style={{ fontSize: '1.5rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        {building.name}
                        <span style={{ color: 'var(--muted-gray)', fontSize: '1.25rem' }}>/ Floors</span>
                    </h2>
                    <button onClick={handleAddFloor} className="btn btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 600 }}>
                        <FaPlus /> Add Floor
                    </button>
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '2rem' }}>
                {/* Floors List */}
                <div className="floors-list">
                    {floors.map(floor => (
                        <div key={floor.id} className="card" style={{ display: 'flex', padding: '1.5rem', marginBottom: '1rem', background: floor.status === 'MAP ACTIVE' ? 'white' : '#fefce8', borderRadius: '0.5rem', boxShadow: 'var(--shadow)', border: floor.status === 'MAP ACTIVE' ? '1px solid var(--border-color)' : '2px solid #fef08a', alignItems: 'center', gap: '1.5rem' }}>
                            <div style={{ width: '60px', height: '60px', background: floor.status === 'MAP ACTIVE' ? '#f1f5f9' : '#fffbeb', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: floor.status === 'MAP ACTIVE' ? '#cbd5e1' : '#fde047' }}>
                                {floor.status === 'MAP ACTIVE' ? <FaMap size={24} /> : <FaUpload size={24} />}
                            </div>
                            <div style={{ flex: 1 }}>
                                <div style={{ fontWeight: 700, fontSize: '1.1rem', marginBottom: '0.25rem' }}>{floor.name}</div>
                                <div style={{ color: 'var(--gray-color)', fontSize: '0.9rem', marginBottom: '0.5rem' }}>{floor.description}</div>
                                <div style={{ display: 'flex', gap: '1rem', fontSize: '0.8rem' }}>
                                    {floor.status === 'MAP ACTIVE' ? (
                                        <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: 'var(--success-color)', fontWeight: 600 }}>
                                            <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'var(--success-color)' }}></span>
                                            MAP ACTIVE
                                        </span>
                                    ) : (
                                        <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: '#ef4444', fontWeight: 600 }}>
                                            <span style={{ width: '0', height: '0', borderLeft: '5px solid transparent', borderRight: '5px solid transparent', borderBottom: '8px solid #ef4444' }}></span>
                                            MAP REQUIRED
                                        </span>
                                    )}
                                    {floor.status === 'MAP ACTIVE' && (
                                        <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: 'var(--gray-color)' }}>
                                            <FaLayerGroup size={12} /> 42 POIs
                                        </span>
                                    )}
                                </div>
                            </div>

                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', alignItems: 'flex-end' }}>
                                {floor.status === 'MAP ACTIVE' && (
                                    <button
                                        className="btn btn-primary"
                                        style={{ fontSize: '0.8rem', padding: '0.25rem 0.5rem' }}
                                        onClick={() => setPreviewFloor(floor)}
                                    >
                                        Preview Map
                                    </button>
                                )}
                                {floor.status === 'MAP REQUIRED' && (
                                    <button className="btn" style={{ background: '#d9f99d', color: '#365314', fontWeight: 700, fontSize: '0.8rem' }}>UPLOAD MAP</button>
                                )}
                            </div>

                            <div style={{ display: 'flex', gap: '1rem', marginLeft: '1rem' }}>
                                <FaPencilAlt
                                    style={{ cursor: 'pointer', color: 'var(--gray-color)' }}
                                    onClick={() => handleEditFloor(floor)}
                                />
                                {floor.status === 'MAP ACTIVE' && (
                                    <>
                                        <div style={{ width: '1px', height: '20px', background: 'var(--border-color)' }}></div>
                                        <span style={{ color: 'var(--primary-color)', fontWeight: 600, fontSize: '1.2rem' }}>A</span>
                                    </>
                                )}
                            </div>
                        </div>
                    ))}
                </div>

                {/* Sidebar Details */}
                <div className="building-sidebar">
                    <div className="card" style={{ padding: '1.5rem', background: '#f8fafc', borderRadius: '0.5rem', border: '1px solid var(--border-color)', marginBottom: '1.5rem' }}>
                        <h3 style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--muted-gray)', letterSpacing: '0.05em', marginBottom: '1rem', textTransform: 'uppercase' }}>Building Details</h3>

                        <div style={{ marginBottom: '1rem' }}>
                            <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-gray)', marginBottom: '0.25rem' }}>CAMPUS ADDRESS</div>
                            <div style={{ fontSize: '0.9rem', fontWeight: 500 }}>102 Innovation Drive, North Campus</div>
                        </div>

                        <div style={{ marginBottom: '1rem' }}>
                            <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-gray)', marginBottom: '0.25rem' }}>COORDINATES</div>
                            <div style={{ background: 'white', padding: '0.5rem', borderRadius: '4px', border: '1px solid var(--border-color)', fontSize: '0.85rem', fontFamily: 'monospace' }}>
                                40.7128° N, 74.0060° W
                            </div>
                        </div>

                        <div style={{ marginBottom: '1.5rem' }}>
                            <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-gray)', marginBottom: '0.25rem' }}>PRIMARY CONTACT</div>
                            <div style={{ fontSize: '0.9rem', fontWeight: 500 }}>Dean of Engineering (Ext. 4410)</div>
                        </div>

                        <div style={{ marginBottom: '1rem' }}>
                            <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-gray)', marginBottom: '0.25rem' }}>ENTRY POINTS (LAT / LONG)</div>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                                <div style={{ background: 'white', padding: '0.5rem', borderRadius: '4px', border: '1px solid var(--border-color)', fontSize: '0.85rem', fontFamily: 'monospace' }}>
                                    Lat: {building.latitude || 'N/A'}
                                </div>
                                <div style={{ background: 'white', padding: '0.5rem', borderRadius: '4px', border: '1px solid var(--border-color)', fontSize: '0.85rem', fontFamily: 'monospace' }}>
                                    Long: {building.longitude || 'N/A'}
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>

            {/* Map Preview Modal */}
            {previewFloor && (
                <div style={{
                    position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
                    background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
                }}>
                    <div style={{ background: 'white', padding: '2rem', borderRadius: '0.5rem', maxWidth: '800px', width: '90%', maxHeight: '90vh', overflow: 'auto' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                            <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>Map: {previewFloor.name}</h3>
                            <button onClick={() => setPreviewFloor(null)} className="btn" style={{ fontSize: '1.5rem', lineHeight: 1 }}>&times;</button>
                        </div>
                        <div style={{ background: '#f1f5f9', height: '400px', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '4px', border: '2px dashed #cbd5e1' }}>
                            <div style={{ textAlign: 'center', color: '#64748b' }}>
                                <FaMap size={48} style={{ marginBottom: '1rem', opacity: 0.5 }} />
                                <div>Map Preview Placeholder</div>
                                <div style={{ fontSize: '0.8rem' }}>{previewFloor.mapFile || 'No file uploaded'}</div>
                            </div>
                        </div>
                        <div style={{ marginTop: '1rem', textAlign: 'right' }}>
                            <button onClick={() => setPreviewFloor(null)} className="btn btn-primary">Close</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default BuildingDetails;
