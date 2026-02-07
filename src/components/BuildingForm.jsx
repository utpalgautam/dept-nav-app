import { useState, useEffect } from 'react';
import { FaSave, FaTimes } from 'react-icons/fa';

const BuildingForm = ({ building, onSave, onCancel }) => {
    const [formData, setFormData] = useState({
        name: '',
        department: '',
        floors: '',
        status: 'IN PROGRESS',
        latitude: '',
        longitude: ''
    });

    useEffect(() => {
        if (building) {
            setFormData({
                name: building.name || '',
                department: building.department || '',
                floors: building.floors || '',
                status: building.status || 'IN PROGRESS',
                latitude: building.latitude || '',
                longitude: building.longitude || ''
            });
        }
    }, [building]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ ...building, ...formData });
    };

    return (
        <div className="card" style={{ maxWidth: '600px', margin: '0 auto', padding: '2rem', background: 'white', borderRadius: '0.5rem', boxShadow: 'var(--shadow)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h2 style={{ fontSize: '1.5rem', fontWeight: 700 }}>
                    {building ? 'Edit Building' : 'Add New Building'}
                </h2>
                <button onClick={onCancel} className="btn" style={{ background: 'transparent', color: 'var(--muted-gray)' }}>
                    <FaTimes size={20} />
                </button>
            </div>

            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label>Building Name</label>
                    <input
                        type="text"
                        name="name"
                        className="form-control"
                        value={formData.name}
                        onChange={handleChange}
                        required
                        placeholder="e.g. Engineering Hall"
                    />
                </div>

                <div className="form-group">
                    <label>Department / Faculty</label>
                    <input
                        type="text"
                        name="department"
                        className="form-control"
                        value={formData.department}
                        onChange={handleChange}
                        required
                        placeholder="e.g. Faculty of Applied Sciences"
                    />
                </div>

                <div className="form-group">
                    <label>Number of Floors</label>
                    <input
                        type="number"
                        name="floors"
                        className="form-control"
                        value={formData.floors}
                        onChange={handleChange}
                        required
                        placeholder="e.g. 5"
                    />
                </div>

                <div className="form-group">
                    <label>Status</label>
                    <select
                        name="status"
                        className="form-control"
                        value={formData.status}
                        onChange={handleChange}
                    >
                        <option value="IN PROGRESS">In Progress</option>
                        <option value="COMPLETE">Complete</option>
                    </select>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    <div className="form-group">
                        <label>Latitude</label>
                        <input
                            type="text"
                            name="latitude"
                            className="form-control"
                            value={formData.latitude}
                            onChange={handleChange}
                            placeholder="e.g. 40.7128"
                        />
                    </div>
                    <div className="form-group">
                        <label>Longitude</label>
                        <input
                            type="text"
                            name="longitude"
                            className="form-control"
                            value={formData.longitude}
                            onChange={handleChange}
                            placeholder="e.g. -74.0060"
                        />
                    </div>
                </div>

                <div style={{ display: 'flex', gap: '1rem', marginTop: '2rem' }}>
                    <button type="button" onClick={onCancel} className="btn btn-outline" style={{ flex: 1 }}>
                        Cancel
                    </button>
                    <button type="submit" className="btn btn-primary" style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                        <FaSave /> Save Building
                    </button>
                </div>
            </form>
        </div>
    );
};

export default BuildingForm;
