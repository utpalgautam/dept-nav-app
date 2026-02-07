import { useState, useEffect } from 'react';

const FacultyForm = ({ faculty, onSave, onCancel }) => {
    const [formData, setFormData] = useState({
        name: '',
        role: '',
        cabin: '',
        building: '',
        floor: ''
    });

    useEffect(() => {
        if (faculty) {
            setFormData({
                name: faculty.name || '',
                role: faculty.role || '',
                cabin: faculty.cabin || '',
                building: faculty.building || '',
                floor: faculty.floor || ''
            });
        }
    }, [faculty]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ ...formData, id: faculty ? faculty.id : Date.now() });
    };

    return (
        <div className="card" style={{ padding: '2rem', maxWidth: '600px', margin: '0 auto' }}>
            <h3 style={{ marginBottom: '1.5rem', fontSize: '1.25rem', fontWeight: 700 }}>
                {faculty ? 'Edit Faculty' : 'Add New Faculty'}
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
                    />
                </div>
                <div className="form-group">
                    <label>Role</label>
                    <input
                        type="text"
                        name="role"
                        className="form-control"
                        value={formData.role}
                        onChange={handleChange}
                    />
                </div>
                <div className="form-group">
                    <label>Cabin No.</label>
                    <input
                        type="text"
                        name="cabin"
                        className="form-control"
                        value={formData.cabin}
                        onChange={handleChange}
                    />
                </div>
                <div className="form-group">
                    <label>Building</label>
                    <input
                        type="text"
                        name="building"
                        className="form-control"
                        value={formData.building}
                        onChange={handleChange}
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
                    />
                </div>
                <div style={{ display: 'flex', gap: '1rem', marginTop: '2rem' }}>
                    <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>Save Faculty</button>
                    <button type="button" className="btn btn-outline" style={{ flex: 1 }} onClick={onCancel}>Cancel</button>
                </div>
            </form>
        </div>
    );
};

export default FacultyForm;
