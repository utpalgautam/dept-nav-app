// src/pages/ReportsPage.jsx
import { useState, useEffect } from 'react';
import Header from '../components/Header';
import Pagination from '../components/Pagination';
import { subscribeToReports, updateReportStatus } from '../services/reportsService';
import ReportDetailModal from '../components/ReportDetailModal';
import { matchesSubsequence } from '../utils/search';

const ReportsPage = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [priorityFilter, setPriorityFilter] = useState('');
  const [selectedReport, setSelectedReport] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  useEffect(() => {
    setLoading(true);
    const unsubscribe = subscribeToReports({ status: statusFilter, type: typeFilter }, (data) => {
      setReports(data || []);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [statusFilter, typeFilter]);

  const handleUpdateReport = async (reportId, status, adminResponse, priority) => {
    try {
      await updateReportStatus(reportId, status, adminResponse, priority);
      // Update local state instead of full reload for "real-time" feel
      setReports(prev => prev.map(r => 
        r.id === reportId 
          ? { ...r, status, priority, admin_response: adminResponse, updated_at: new Date() } 
          : r
      ));
      setSelectedReport(null);
    } catch (err) {
      console.error('Error updating report:', err);
      alert('Failed to update report status.');
    }
  };

  const getFilteredReports = () => {
    let filtered = (reports || []).filter(report => {
      const userName = report?.user_name || '';
      const description = report?.description || '';
      
      const matchesSearch =
        matchesSubsequence(searchQuery, userName) ||
        matchesSubsequence(searchQuery, description);
      
      const matchesStatus = !statusFilter || report.status === statusFilter;
      const matchesType = !typeFilter || report.type === typeFilter;
      const matchesPriority = !priorityFilter || report.priority === priorityFilter;
      
      return matchesSearch && matchesStatus && matchesType && matchesPriority;
    });

    return filtered;
  };

  const filteredReports = getFilteredReports();

  const getStatusBadgeClass = (status) => {
    switch (status) {
      case 'open': return 'report-pill report-pill-orange';
      case 'in_progress': return 'report-pill report-pill-blue';
      case 'resolved': return 'report-pill report-pill-green';
      default: return 'report-pill report-pill-gray';
    }
  };

  const issueTypes = [...new Set(reports.map(r => r.type))].filter(Boolean);

  return (
    <div className="reports-page">
      <Header
        title="Reports Management"
        searchTerm={searchQuery}
        onSearchChange={e => {
          setSearchQuery(e.target.value);
          setCurrentPage(1);
        }}
      />

      <div className="reports-toolbar">
        <div className="reports-filters">
          <select 
            className="reports-select"
            value={statusFilter}
            onChange={e => { setStatusFilter(e.target.value); setCurrentPage(1); }}
          >
            <option value="">All Statuses</option>
            <option value="open">Open</option>
            <option value="in_progress">In Progress</option>
            <option value="resolved">Resolved</option>
          </select>

          <select 
            className="reports-select"
            value={typeFilter}
            onChange={e => { setTypeFilter(e.target.value); setCurrentPage(1); }}
          >
            <option value="">All Issue Types</option>
            {issueTypes.map(type => (
              <option key={type} value={type}>{type}</option>
            ))}
          </select>

          <select 
            className="reports-select"
            value={priorityFilter}
            onChange={e => { setPriorityFilter(e.target.value); setCurrentPage(1); }}
          >
            <option value="">All Priorities</option>
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
          </select>
        </div>
      </div>

      {error && <div className="reports-error">{error}</div>}

      <div className="reports-table-container">
        <table className="reports-table">
          <thead>
            <tr>
              <th style={{ textAlign: 'left', paddingLeft: '1.5rem' }}>User Name</th>
              <th style={{ textAlign: 'center' }}>Issue Type</th>
              <th style={{ textAlign: 'center' }}>Priority</th>
              <th style={{ textAlign: 'left' }}>Description</th>
              <th style={{ textAlign: 'center' }}>Status</th>
              <th style={{ textAlign: 'center' }}>Date</th>
              <th style={{ textAlign: 'right', paddingRight: '1.5rem' }}>Action</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="6" style={{ textAlign: 'center', padding: '2rem' }}>Loading...</td></tr>
            ) : filteredReports.length === 0 ? (
              <tr><td colSpan="6" style={{ textAlign: 'center', padding: '2rem' }}>No reports found.</td></tr>
            ) : (
              filteredReports
                .slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage)
                .map(report => (
                  <tr key={report.id} onClick={() => setSelectedReport(report)} className="report-row">
                    <td style={{ textAlign: 'left', paddingLeft: '1.5rem' }}>
                      <div className="report-user-cell">
                        <div className="report-user-name">{report.user_name || 'Anonymous'}</div>
                        <div className="report-user-email">{report.userEmail}</div>
                      </div>
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <span className="report-type-text">{report.type}</span>
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <span className={`report-priority-tag priority-${report.priority || 'medium'}`}>
                        {(report.priority || 'medium').toUpperCase()}
                      </span>
                    </td>
                    <td style={{ textAlign: 'left' }}>
                      <div className="report-desc-text">
                        {report.description?.length > 50 
                          ? report.description.substring(0, 50) + '...' 
                          : report.description}
                      </div>
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <span className={getStatusBadgeClass(report.status)}>
                        {report.status?.replace('_', ' ').toUpperCase()}
                      </span>
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <span className="report-date-text">
                        {report.created_at ? new Date(report.created_at).toLocaleDateString() : 'N/A'}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right', paddingRight: '1.5rem' }}>
                      <button className="report-view-btn" onClick={(e) => { e.stopPropagation(); setSelectedReport(report); }}>
                        Review
                      </button>
                    </td>
                  </tr>
                ))
            )}
          </tbody>
        </table>
      </div>

      <Pagination
        currentPage={currentPage}
        totalItems={filteredReports.length}
        itemsPerPage={itemsPerPage}
        onPageChange={setCurrentPage}
      />

      {selectedReport && (
        <ReportDetailModal
          report={selectedReport}
          onClose={() => setSelectedReport(null)}
          onUpdate={handleUpdateReport}
        />
      )}
    </div>
  );
};

export default ReportsPage;
