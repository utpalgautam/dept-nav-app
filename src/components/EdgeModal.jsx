// src/components/EdgeModal.jsx
import React, { useState, useEffect } from 'react';
import { FaTimes, FaSave } from 'react-icons/fa';

const EdgeModal = ({ isOpen, onClose, onSave, edgeData, fromNode, toNode }) => {
    const [weight, setWeight] = useState(1);

    useEffect(() => {
        if (edgeData) {
            setWeight(edgeData.weight || 1);
        }
    }, [edgeData]);

    if (!isOpen) return null;

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ weight: parseFloat(weight) });
    };

    return (
        <div className="modal-overlay">
            <div className="modal-content">
                <div className="modal-header">
                    <h3>Edit Edge</h3>
                    <button onClick={onClose} className="close-btn"><FaTimes /></button>
                </div>
                <div className="edge-info-pills">
                    <span className="pill">{fromNode?.label || 'Unknown'}</span>
                    <span className="arrow">↔</span>
                    <span className="pill">{toNode?.label || 'Unknown'}</span>
                </div>
                <form onSubmit={handleSubmit}>
                    <div className="form-group">
                        <label>Edge Weight (Distance/Cost)</label>
                        <input
                            type="number"
                            step="0.001"
                            value={weight}
                            onChange={(e) => setWeight(e.target.value)}
                            placeholder="e.g. 1.0"
                            required
                            className="ir-input-pill"
                        />
                    </div>
                    <div className="modal-footer">
                        <button type="button" onClick={onClose} className="ir-btn-black">Cancel</button>
                        <button type="submit" className="ir-btn-save">
                            <FaSave /> Update Edge
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default EdgeModal;
