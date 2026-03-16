// src/components/NodeModal.jsx
import React, { useState, useEffect } from 'react';
import { FaTimes, FaSave } from 'react-icons/fa';

const NodeModal = ({ isOpen, onClose, onSave, nodeData, isEditing }) => {
    const [label, setLabel] = useState('');
    const [type, setType] = useState('room');

    useEffect(() => {
        if (nodeData) {
            setLabel(nodeData.label || '');
            setType(nodeData.type || 'room');
        }
    }, [nodeData]);

    if (!isOpen) return null;

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ label, type });
        setLabel('');
        setType('room');
    };

    return (
        <div className="modal-overlay">
            <div className="modal-content">
                <div className="modal-header">
                    <h3>{isEditing ? 'Edit Node' : 'Add New Node'}</h3>
                    <button onClick={onClose} className="close-btn"><FaTimes /></button>
                </div>
                <form onSubmit={handleSubmit}>
                    <div className="form-group">
                        <label>Node Label</label>
                        <input
                            type="text"
                            value={label}
                            onChange={(e) => setLabel(e.target.value)}
                            placeholder="e.g. Room 101, Stairs A"
                            required
                            className="ir-input-pill"
                        />
                    </div>
                    <div className="form-group">
                        <label>Node Type</label>
                        <select
                            value={type}
                            onChange={(e) => setType(e.target.value)}
                            className="ir-input-pill"
                        >
                            <option value="room">Room</option>
                            <option value="hallway">Hallway</option>
                            <option value="stairs">Stairs</option>
                        </select>
                    </div>
                    <div className="modal-footer">
                        <button type="button" onClick={onClose} className="ir-btn-black">Cancel</button>
                        <button type="submit" className="ir-btn-save">
                            <FaSave /> {isEditing ? 'Update Node' : 'Save Node'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default NodeModal;
