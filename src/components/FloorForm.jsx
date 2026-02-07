import { useState, useEffect } from 'react';
import { FaSave, FaTimes, FaUpload } from 'react-icons/fa';

const FloorForm = ({ floor, onSave, onCancel }) => {
    const [formData, setFormData] = useState({
        name: '',
        description: '',
        status: 'MAP REQUIRED',
        mapFile: null
    });

    useEffect(() => {
        if (floor) {
            setFormData({
                name: floor.name || '',
                description: floor.description || '',
                status: floor.status || 'MAP REQUIRED',
                mapFile: null // Don't preload file object
            });
        }
    }, [floor]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleFileChange = (e) => {
        // Simulate file selection
        if (e.target.files && e.target.files[0]) {
            setFormData(prev => ({
                ...prev,
                mapFile: e.target.files[0].name,
                status: 'MAP ACTIVE' // Auto-update status on upload
            }));
        }
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ ...floor, ...formData });
    };

    return (
        <div className="card" style={{ maxWidth: '600px', margin: '0 auto', padding: '2rem', background: 'white', borderRadius: '0.5rem', boxShadow: 'var(--shadow)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h2 style={{ fontSize: '1.5rem', fontWeight: 700 }}>
                    {floor ? 'Edit Floor' : 'Add New Floor'}
                </h2>
                <button onClick={onCancel} className="btn" style={{ background: 'transparent', color: 'var(--muted-gray)' }}>
                    <FaTimes size={20} />
                </button>
            </div>

            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label>Floor Name</label>
                    <input
                        type="text"
                        name="name"
                        className="form-control"
                        value={formData.name}
                        onChange={handleChange}
                        required
                        placeholder="e.g. Floor 1 (Ground)"
                    />
                </div>

                <div className="form-group">
                    <label>Description / Primary Functions</label>
                    <textarea
                        name="description"
                        className="form-control"
                        value={formData.description}
                        onChange={handleChange}
                        rows="3"
                        placeholder="e.g. Admin Offices, Main Lobby, Cafeteria"
                        style={{ resize: 'vertical' }}
                    />
                </div>

                <div className="form-group">
                    <label>Floor Map</label>
                    <div style={{ border: '2px dashed var(--border-color)', borderRadius: '0.5rem', padding: '2rem', textAlign: 'center', background: '#f8fafc', cursor: 'pointer', position: 'relative' }}>
                        <input
                            type="file"
                            onChange={handleFileChange}
                            style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', opacity: 0, cursor: 'pointer' }}
                        />
                        <FaUpload size={24} color="var(--gray-color)" style={{ marginBottom: '0.5rem' }} />
                        <div style={{ fontWeight: 600, color: 'var(--dark-color)' }}>
                            {formData.mapFile ? formData.mapFile : 'Click to upload map file'}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--muted-gray)' }}>Supports PNG, SVG, PDF</div>
                    </div>
                </div>

                <div className="form-group">
                    <label>Status</label>
                    <select
                        name="status"
                        className="form-control"
                        value={formData.status}
                        onChange={handleChange}
                    >
                        <option value="MAP REQUIRED">Map Required</option>
                        <option value="MAP ACTIVE">Map Active</option>
                    </select>
                </div>

                <div style={{ display: 'flex', gap: '1rem', marginTop: '2rem' }}>
                    <button type="button" onClick={onCancel} className="btn btn-outline" style={{ flex: 1 }}>
                        Cancel
                    </button>
                    <button type="submit" className="btn btn-primary" style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                        <FaSave /> Save Floor
                    </button>
                </div>
            </form>
        </div>
    );
};

export default FloorForm;
