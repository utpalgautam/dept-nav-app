// src/components/ReportDetailModal.jsx
import { useState } from 'react';
import { LuX, LuUser, LuInfo, LuMessageSquare, LuClock, LuMapPin, LuCheck, LuLoaderCircle } from 'react-icons/lu';

const ReportDetailModal = ({ report, onClose, onUpdate }) => {
  const [status, setStatus] = useState(report.status || 'open');
  const [priority, setPriority] = useState(report.priority || 'medium');
  const [adminResponse, setAdminResponse] = useState(report.admin_response || '');
  const [saving, setSaving] = useState(false);

  const handleUpdate = async () => {
    setSaving(true);
    try {
      // Create a copy of report data to update
      const updateData = {
          status,
          priority,
          admin_response: adminResponse
      };
      await onUpdate(report.id, status, adminResponse, priority);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="report-modal-overlay" onClick={onClose}>
      <div className="report-modal-content" onClick={e => e.stopPropagation()}>
        <div className="report-modal-header">
          <div className="report-modal-header-left">
            <span className={`report-modal-status-badge status-${status}`}>
              {status.replace('_', ' ').toUpperCase()}
            </span>
            <h2 className="report-modal-title">Report Details</h2>
          </div>
          <button className="report-modal-close" onClick={onClose}><LuX /></button>
        </div>

        <div className="report-modal-body">
          <div className="report-detail-grid">
            {/* Left Column: Info */}
            <div className="report-info-section">
              <div className="report-detail-item">
                <div className="report-detail-label"><LuUser /> User</div>
                <div className="report-detail-value">
                  <strong>{report.user_name || 'Anonymous'}</strong>
                  <div className="report-detail-subtext">{report.userEmail}</div>
                </div>
              </div>

              <div className="report-detail-item">
                <div className="report-detail-label"><LuInfo /> Issue Type</div>
                <div className="report-detail-value">{report.type}</div>
              </div>

              <div className="report-detail-item">
                <div className="report-detail-label"><LuClock /> Date Submitted</div>
                <div className="report-detail-value">
                  {report.created_at ? new Date(report.created_at).toLocaleString() : 'N/A'}
                </div>
              </div>

              {report.location && (
                <div className="report-detail-item">
                  <div className="report-detail-label"><LuMapPin /> Location</div>
                  <div className="report-detail-value">
                    Lat: {report.location.lat}, Lng: {report.location.lng}
                  </div>
                </div>
              )}
            </div>

            {/* Right Column: Description */}
            <div className="report-desc-section">
              <div className="report-detail-label"><LuMessageSquare /> Full Description</div>
              <div className="report-description-box">
                {report.description}
              </div>
            </div>
          </div>

          <div className="report-action-section">
             <div className="report-detail-label">Admin Actions</div>
             <div className="report-action-controls">
                <div className="report-form-group">
                  <label>Update Status</label>
                  <select 
                    className="report-modal-select"
                    value={status} 
                    onChange={e => setStatus(e.target.value)}
                  >
                    <option value="open">Open</option>
                    <option value="in_progress">In Progress</option>
                    <option value="resolved">Resolved</option>
                  </select>
                </div>

                <div className="report-form-group">
                  <label>Priority</label>
                  <select 
                    className="report-modal-select"
                    value={priority} 
                    onChange={e => setPriority(e.target.value)}
                  >
                    <option value="low">Low</option>
                    <option value="medium">Medium</option>
                    <option value="high">High</option>
                  </select>
                </div>

                <div className="report-form-group full-width">
                  <label>Admin Response</label>
                  <textarea 
                    className="report-modal-textarea"
                    placeholder="e.g. Fixed missing path near CSE block"
                    value={adminResponse}
                    onChange={e => setAdminResponse(e.target.value)}
                  />
                </div>
             </div>
          </div>
        </div>

        <div className="report-modal-footer">
          <button className="report-modal-btn report-modal-btn-cancel" onClick={onClose}>Cancel</button>
          <button 
            className="report-modal-btn report-modal-btn-save" 
            onClick={handleUpdate}
            disabled={saving}
          >
            {saving ? <><LuLoaderCircle className="spin" /> Saving...</> : <><LuCheck /> Update Report</>}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReportDetailModal;
