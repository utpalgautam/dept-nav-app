import { useState, useEffect } from 'react';

const HallsLabsForm = ({ item, onSave, onCancel }) => {
    const [formData, setFormData] = useState({
        name: '',
        type: 'LABORATORY',
        building: '',
        floor: '',
        capacity: '',
        status: 'ACTIVE'
    });

    useEffect(() => {
        if (item) {
            setFormData({
                name: item.name || '',
                type: item.type || 'LABORATORY',
                building: item.building || '',
                floor: item.floor || '',
                capacity: item.capacity || '',
                status: item.status || 'ACTIVE'
            });
        }
    }, [item]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ ...formData, id: item ? item.id : Date.now() });
    };

    return (
        <div className="card" style={{ padding: '2rem', maxWidth: '600px', margin: '0 auto' }}>
            <h3 style={{ marginBottom: '1.5rem', fontSize: '1.25rem', fontWeight: 700 }}>
                {item ? 'Edit Hall/Lab' : 'Add New Hall/Lab'}
            </h3>
            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label>Name</label>
                    <input
                        type="text"
                        name="name"
                        className="form-control"
                        value={formData.name}
                        onChange={handleChange}
                        required
                        placeholder="e.g. Lab 202"
                    />
                </div>
                <div className="form-group">
                    <label>Type</label>
                    <select
                        name="type"
                        className="form-control"
                        value={formData.type}
                        onChange={handleChange}
                    >
                        <option value="LABORATORY">Laboratory</option>
                        <option value="LECTURE HALL">Lecture Hall</option>
                        <option value="SEMINAR ROOM">Seminar Room</option>
                        <option value="AUDITORIUM">Auditorium</option>
                    </select>
                </div>
                <div className="form-group">
                    <label>Building</label>
                    <input
                        type="text"
                        name="building"
                        className="form-control"
                        value={formData.building}
                        onChange={handleChange}
                        placeholder="e.g. Engineering Block A"
                    />
                </div>
                <div className="form-group">
                    <label>Floor</label>
                    <input
                        type="text"
                        name="floor"
                        className="form-control"
                        value={formData.floor}
                        onChange={handleChange}
                        placeholder="e.g. 2nd Floor"
                    />
                </div>
                <div className="form-group">
                    <label>Capacity</label>
                    <input
                        type="number"
                        name="capacity"
                        className="form-control"
                        value={formData.capacity}
                        onChange={handleChange}
                        placeholder="e.g. 45"
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
                        <option value="ACTIVE">Active</option>
                        <option value="MAINTENANCE">Maintenance</option>
                        <option value="CLOSED">Closed</option>
                    </select>
                </div>
                <div style={{ display: 'flex', gap: '1rem', marginTop: '2rem' }}>
                    <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>Save</button>
                    <button type="button" className="btn btn-outline" style={{ flex: 1 }} onClick={onCancel}>Cancel</button>
                </div>
            </form>
        </div>
    );
};

export default HallsLabsForm;
