import { useState, useRef, useEffect } from 'react';
import { FaCloudUploadAlt } from 'react-icons/fa';
import { fetchFloors } from '../services/floorService';

const HallsLabsForm = ({ item, buildings = [], onSave, onCancel }) => {
    const fileInputRef = useRef(null);

    const [formData, setFormData] = useState({
        name: '',
        type: 'LECTURE HALL',
        category: 'HALL',
        building: '',
        floor: '',
        status: 'ACTIVE',
        contactPerson: '',
        roomNumber: '',
        department: '',
        incharge: '',
        inchargeEmail: '',
        imageUrl: '',
        imageFile: null,
        _localPreview: ''
    });

    const [loading, setLoading] = useState(false);
    const [availableFloors, setAvailableFloors] = useState([]);
    const [isFloorsLoading, setIsFloorsLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (item) {
            setFormData({
                name: item.name || '',
                type: item.type || (item.category === 'LAB' ? 'LABORATORY' : 'LECTURE HALL'),
                category: item.category || 'HALL',
                building: item.building || '',
                floor: item.floor || '',
                status: item.status || 'ACTIVE',
                contactPerson: item.contactPerson || '',
                roomNumber: item.roomNumber || '',
                department: item.department || '',
                incharge: item.incharge || '',
                inchargeEmail: item.inchargeEmail || '',
                imageUrl: item.imageUrl || '',
                imageFile: null,
                _localPreview: ''
            });
            // Load floors immediately for edit mode
            if (item.building) {
                loadFloors(item.building);
            }
        }
    }, [item]);

    const loadFloors = async (buildingId) => {
        if (!buildingId) {
            setAvailableFloors([]);
            return;
        }
        setIsFloorsLoading(true);
        try {
            const floors = await fetchFloors(buildingId);
            // Sort floors numerically
            const sortedFloors = floors.sort((a, b) => a.floorNumber - b.floorNumber);
            setAvailableFloors(sortedFloors);
        } catch (err) {
            console.error('Error loading floors:', err);
            setError('Failed to load floors for the selected building.');
        } finally {
            setIsFloorsLoading(false);
        }
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        if (name === 'building') {
            setFormData(prev => ({ 
                ...prev, 
                building: value,
                floor: '' // Reset floor when building changes
            }));
            loadFloors(value);
        } else {
            setFormData(prev => ({ ...prev, [name]: value }));
        }
    };

    const handleCategoryChange = (category) => {
        setFormData(prev => ({
            ...prev,
            category,
            type: category === 'LAB' ? 'LABORATORY' : 'LECTURE HALL'
        }));
    };

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            if (file.size > 5 * 1024 * 1024) {
                setError("Image cannot exceed 5MB.");
                return;
            }
            setFormData(prev => ({
                ...prev,
                imageFile: file,
                _localPreview: URL.createObjectURL(file)
            }));
            setError('');
        }
    };

    const triggerUpload = () => {
        fileInputRef.current?.click();
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const dataToSave = { ...formData };
            if (item) dataToSave.id = item.id;
            await onSave(dataToSave);
        } catch (err) {
            setError(err.message || 'Failed to save. Please check your connection.');
            setLoading(false);
        }
    };

    const isLab = formData.category === 'LAB';
    const displayMap = formData._localPreview || formData.imageUrl;

    const renderInputFields = () => (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
            <div className="hl-form-grid">
                <div className="hl-form-group">
                    <label>Name</label>
                    <input
                        type="text"
                        name="name"
                        className="hl-input-pill"
                        value={formData.name}
                        onChange={handleChange}
                        placeholder={isLab ? "System Software Laboratory" : "Seminar Hall"}
                        required
                    />
                </div>
                <div className="hl-form-group">
                    <label>Type</label>
                    <select name="type" className="hl-input-pill" value={formData.type} onChange={handleChange}>
                        {isLab ? (
                            <option value="LABORATORY">Laboratory</option>
                        ) : (
                            <>
                                <option value="LECTURE HALL">Lecture Hall</option>
                                <option value="SEMINAR ROOM">Seminar Room</option>
                                <option value="AUDITORIUM">Auditorium</option>
                            </>
                        )}
                    </select>
                </div>
            </div>

            <div className="hl-form-grid">
                <div className="hl-form-group">
                    <label>Building</label>
                    <select
                        name="building"
                        className="hl-input-pill"
                        value={formData.building}
                        onChange={handleChange}
                        required
                    >
                        <option value="">Select Building</option>
                        {buildings.map(b => (
                            <option key={b.id} value={b.id}>{b.name}</option>
                        ))}
                    </select>
                </div>
                <div className="hl-form-group">
                    <label>Floor</label>
                    <select
                        name="floor"
                        className="hl-input-pill"
                        value={formData.floor}
                        onChange={handleChange}
                        disabled={!formData.building || isFloorsLoading}
                        required
                    >
                        <option value="" disabled>
                            {!formData.building ? 'Select building first' : isFloorsLoading ? 'Loading floors...' : 'Select Floor'}
                        </option>
                        {availableFloors.map(f => (
                            <option key={f.id} value={f.floorNumber}>
                                {f.name || `Floor ${f.floorNumber}`}
                            </option>
                        ))}
                    </select>
                </div>
            </div>

            <div className="hl-form-grid">
                <div className="hl-form-group">
                    <label>Status</label>
                    <select name="status" className="hl-input-pill" value={formData.status} onChange={handleChange}>
                        <option value="ACTIVE">Active</option>
                        <option value="MAINTENANCE">Maintenance</option>
                        <option value="CLOSED">Closed</option>
                    </select>
                </div>
                <div className="hl-form-group">
                    <label>Department</label>
                    <input
                        type="text"
                        name="department"
                        className="hl-input-pill"
                        value={formData.department}
                        onChange={handleChange}
                        placeholder="e.g. Computer Science"
                    />
                </div>
            </div>

            {isLab === false && (
                <div className="hl-form-grid">
                    <div className="hl-form-group">
                        <label>Contact Person</label>
                        <input
                            type="text"
                            name="contactPerson"
                            className="hl-input-pill"
                            value={formData.contactPerson}
                            onChange={handleChange}
                            placeholder="Dr. Ramesh Kumar"
                        />
                    </div>
                    <div className="hl-form-group">
                        <label>Room Number</label>
                        <input
                            type="text"
                            name="roomNumber"
                            className="hl-input-pill"
                            value={formData.roomNumber}
                            onChange={handleChange}
                            placeholder="Room 203"
                        />
                    </div>
                </div>
            )}
 
            {isLab && (
                <>
                    <div className="hl-form-grid">
                        <div className="hl-form-group">
                            <label>Room Number</label>
                            <input
                                type="text"
                                name="roomNumber"
                                className="hl-input-pill"
                                value={formData.roomNumber}
                                onChange={handleChange}
                                placeholder="L201"
                            />
                        </div>
                    </div>
                    <div className="hl-form-grid">
                        <div className="hl-form-group">
                            <label>Lab In-charge</label>
                            <input
                                type="text"
                                name="incharge"
                                className="hl-input-pill"
                                value={formData.incharge}
                                onChange={handleChange}
                                placeholder="Mr. Anil Singh"
                            />
                        </div>
                        <div className="hl-form-group">
                            <label>In-charge Email</label>
                            <input
                                type="email"
                                name="inchargeEmail"
                                className="hl-input-pill"
                                value={formData.inchargeEmail}
                                onChange={handleChange}
                                placeholder="anil@university.edu"
                            />
                        </div>
                    </div>
                </>
            )}
        </div>
    );

    const renderUploadZone = () => (
        <div className="hl-upload-zone" onClick={triggerUpload}>
            <input
                type="file"
                accept="image/png, image/jpeg, image/webp"
                className="hl-hidden-input"
                ref={fileInputRef}
                onChange={handleImageChange}
            />
            {displayMap ? (
                <img src={displayMap} alt="Map Preview" className="hl-upload-preview" />
            ) : (
                <>
                    <FaCloudUploadAlt size={32} className="hl-upload-icon" />
                    <span className="hl-upload-label">Upload Map</span>
                </>
            )}
        </div>
    );

    return (
        <form onSubmit={handleSubmit} style={{ width: '100%', margin: '0 auto' }}>
            {error && (
                <div style={{ padding: '1rem', marginBottom: '1.5rem', background: '#fee', border: '1px solid #fcc', borderRadius: '0.5rem', color: '#c33' }}>
                    {error}
                </div>
            )}

            <div className="hl-form-container">
                <div className={`hl-form-inner-box ${item ? 'dashed' : ''}`}>
                    {!item && (
                        <div className="hl-type-toggle">
                            <button
                                type="button"
                                className={`hl-type-btn ${!isLab ? 'active' : 'inactive'}`}
                                onClick={() => handleCategoryChange('HALL')}
                            >
                                Add New Hall
                            </button>
                            <button
                                type="button"
                                className={`hl-type-btn ${isLab ? 'active' : 'inactive'}`}
                                onClick={() => handleCategoryChange('LAB')}
                            >
                                Add New Lab
                            </button>
                        </div>
                    )}

                    {item && (
                        <h2 style={{ fontSize: '1.8rem', fontWeight: 600, marginBottom: '2.5rem', color: '#111' }}>
                            {formData.name || (isLab ? 'Edit Lab' : 'Edit Hall')}
                        </h2>
                    )}

                    <div style={{
                        display: 'grid',
                        gridTemplateColumns: item ? '1fr 2fr' : '2fr 1fr',
                        gap: '3rem',
                        alignItems: 'start'
                    }}>
                        {item ? (
                            <>
                                {renderUploadZone()}
                                {renderInputFields()}
                            </>
                        ) : (
                            <>
                                {renderInputFields()}
                                {renderUploadZone()}
                            </>
                        )}
                    </div>
                </div>

                <div className="hl-form-actions" style={{ justifyContent: 'center', width: '100%' }}>
                    <button
                        type="submit"
                        className="hl-btn-save"
                        disabled={loading}
                        style={{ flex: item ? '0 1 650px' : '1' }}
                    >
                        {loading ? 'Saving...' : (item ? 'Save' : `Save ${isLab ? 'Lab' : 'Hall'}`)}
                    </button>
                    {item && (
                        <button
                            type="button"
                            className="hl-btn-cancel"
                            onClick={onCancel}
                            disabled={loading}
                            style={{ flex: '0 1 650px' }}
                        >
                            Cancel
                        </button>
                    )}
                </div>
            </div>
        </form>
    );
};

export default HallsLabsForm;
