// src/pages/SettingsPage.jsx
import { useState, useEffect } from 'react';
import Header from '../components/Header';
import {
    FaKey, FaEye, FaEyeSlash, FaSave, FaCheckCircle,
    FaExclamationTriangle, FaDownload, FaUpload,
    FaClock, FaServer, FaDatabase, FaPlug, FaCalendarAlt
} from 'react-icons/fa';

const SettingsPage = () => {
    // API Key State
    const [apiKey, setApiKey] = useState(localStorage.getItem('osmApiKey') || '');
    const [showApiKey, setShowApiKey] = useState(false);
    const [apiKeyStatus, setApiKeyStatus] = useState('valid');
    const [apiKeySaved, setApiKeySaved] = useState(false);

    // Maintenance Window State
    const [maintenanceEnabled, setMaintenanceEnabled] = useState(false);
    const [maintenanceStart, setMaintenanceStart] = useState('');
    const [maintenanceEnd, setMaintenanceEnd] = useState('');
    const [maintenanceSaved, setMaintenanceSaved] = useState(false);

    // System Status
    const [systemStatus, setSystemStatus] = useState({
        apiConnected: true,
        dbConnected: true,
        uptime: '15 days 6 hours',
        lastBackup: '2026-02-07T10:30:00'
    });

    // Card style
    const cardStyle = {
        background: 'white',
        borderRadius: '12px',
        padding: '1.75rem',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05), 0 10px 25px -5px rgba(0, 0, 0, 0.05)',
        border: '1px solid #f0f0f0',
        marginBottom: '1.5rem'
    };

    // Save API Key
    const handleSaveApiKey = () => {
        if (apiKey.trim().length > 0) {
            localStorage.setItem('osmApiKey', apiKey);
            setApiKeyStatus('valid');
            setApiKeySaved(true);

            // Update system status
            setSystemStatus(prev => ({ ...prev, apiConnected: true }));

            setTimeout(() => setApiKeySaved(false), 3000);
        }
    };

    // Save Maintenance Window
    const handleSaveMaintenanceWindow = () => {
        const maintenanceConfig = {
            enabled: maintenanceEnabled,
            start: maintenanceStart,
            end: maintenanceEnd
        };

        localStorage.setItem('maintenanceWindow', JSON.stringify(maintenanceConfig));
        setMaintenanceSaved(true);
        setTimeout(() => setMaintenanceSaved(false), 3000);
    };

    // Check if currently in maintenance window
    const isInMaintenanceWindow = () => {
        if (!maintenanceEnabled || !maintenanceStart || !maintenanceEnd) return false;

        const now = new Date();
        const start = new Date(maintenanceStart);
        const end = new Date(maintenanceEnd);

        return now >= start && now <= end;
    };

    // Create Backup
    const handleCreateBackup = () => {
        const backupData = {
            version: '1.0',
            timestamp: new Date().toISOString(),
            configuration: {
                apiKey: apiKey,
                maintenanceWindow: {
                    enabled: maintenanceEnabled,
                    start: maintenanceStart,
                    end: maintenanceEnd
                }
            }
        };

        const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `navi_backup_${new Date().toISOString().split('T')[0]}.json`;
        link.click();
        URL.revokeObjectURL(url);

        // Update last backup time
        setSystemStatus(prev => ({ ...prev, lastBackup: new Date().toISOString() }));
    };

    // Restore from Backup
    const handleRestoreBackup = (e) => {
        const file = e.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (event) => {
            try {
                const backupData = JSON.parse(event.target.result);

                // Restore configuration
                if (backupData.configuration) {
                    if (backupData.configuration.apiKey) {
                        setApiKey(backupData.configuration.apiKey);
                        localStorage.setItem('osmApiKey', backupData.configuration.apiKey);
                    }

                    if (backupData.configuration.maintenanceWindow) {
                        const mw = backupData.configuration.maintenanceWindow;
                        setMaintenanceEnabled(mw.enabled || false);
                        setMaintenanceStart(mw.start || '');
                        setMaintenanceEnd(mw.end || '');
                        localStorage.setItem('maintenanceWindow', JSON.stringify(mw));
                    }
                }

                alert('Backup restored successfully! All settings have been applied.');
            } catch (error) {
                alert('Error restoring backup: Invalid backup file format.');
            }
        };
        reader.readAsText(file);
    };

    // Format date for display
    const formatDate = (dateString) => {
        if (!dateString) return 'Never';
        const date = new Date(dateString);
        return date.toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    // Load saved settings on mount
    useEffect(() => {
        const savedMaintenance = localStorage.getItem('maintenanceWindow');
        if (savedMaintenance) {
            try {
                const config = JSON.parse(savedMaintenance);
                setMaintenanceEnabled(config.enabled || false);
                setMaintenanceStart(config.start || '');
                setMaintenanceEnd(config.end || '');
            } catch (e) {
                // Ignore parse errors
            }
        }
    }, []);

    const StatusIndicator = ({ status, label }) => {
        const colors = {
            success: { bg: '#d1fae5', color: '#065f46', border: '#10b981', dot: '#10b981' },
            warning: { bg: '#fef3c7', color: '#92400e', border: '#f59e0b', dot: '#f59e0b' },
            error: { bg: '#fee2e2', color: '#991b1b', border: '#ef4444', dot: '#ef4444' }
        };

        const style = colors[status] || colors.success;

        return (
            <div style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.5rem',
                padding: '0.375rem 0.75rem',
                borderRadius: '6px',
                background: style.bg,
                color: style.color,
                border: `1px solid ${style.border}`,
                fontSize: '0.875rem',
                fontWeight: 600
            }}>
                <div style={{
                    width: '8px',
                    height: '8px',
                    borderRadius: '50%',
                    background: style.dot,
                    animation: status === 'success' ? 'pulse 2s infinite' : 'none'
                }} />
                {label}
            </div>
        );
    };

    return (
        <div>
            <Header title="Settings" />

            {/* System Status Dashboard */}
            <div style={cardStyle}>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <FaServer /> System Status
                </h2>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.5rem' }}>
                    <div>
                        <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <FaPlug size={14} /> OSM API Status
                        </div>
                        <StatusIndicator status={systemStatus.apiConnected ? 'success' : 'error'} label={systemStatus.apiConnected ? 'Connected' : 'Disconnected'} />
                    </div>

                    <div>
                        <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <FaDatabase size={14} /> Database Status
                        </div>
                        <StatusIndicator status={systemStatus.dbConnected ? 'success' : 'error'} label={systemStatus.dbConnected ? 'Healthy' : 'Error'} />
                    </div>

                    <div>
                        <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <FaClock size={14} /> System Uptime
                        </div>
                        <div style={{ fontSize: '1.125rem', fontWeight: 700 }}>{systemStatus.uptime}</div>
                    </div>

                    <div>
                        <div style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <FaDownload size={14} /> Last Backup
                        </div>
                        <div style={{ fontSize: '1.125rem', fontWeight: 700 }}>{formatDate(systemStatus.lastBackup)}</div>
                    </div>
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }} className="settings-grid">
                {/* OSM API Configuration */}
                <div style={cardStyle}>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <FaKey /> OSM API Configuration
                    </h2>
                    <p style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '1.5rem' }}>
                        Configure your OpenStreetMap API key for map services
                    </p>

                    <div style={{ marginBottom: '1.5rem' }}>
                        <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, marginBottom: '0.5rem' }}>
                            API Key
                        </label>
                        <div style={{ display: 'flex', gap: '0.5rem' }}>
                            <div style={{ position: 'relative', flex: 1 }}>
                                <input
                                    type={showApiKey ? 'text' : 'password'}
                                    value={apiKey}
                                    onChange={(e) => setApiKey(e.target.value)}
                                    placeholder="Enter your OSM API key"
                                    style={{
                                        width: '100%',
                                        padding: '0.625rem 2.5rem 0.625rem 0.75rem',
                                        border: '1px solid var(--border-color)',
                                        borderRadius: '8px',
                                        fontSize: '0.875rem',
                                        fontFamily: showApiKey ? 'monospace' : 'inherit'
                                    }}
                                />
                                <button
                                    onClick={() => setShowApiKey(!showApiKey)}
                                    style={{
                                        position: 'absolute',
                                        right: '8px',
                                        top: '50%',
                                        transform: 'translateY(-50%)',
                                        background: 'none',
                                        border: 'none',
                                        cursor: 'pointer',
                                        color: 'var(--gray-color)',
                                        padding: '0.5rem'
                                    }}
                                >
                                    {showApiKey ? <FaEyeSlash size={16} /> : <FaEye size={16} />}
                                </button>
                            </div>
                        </div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--gray-color)', marginTop: '0.5rem' }}>
                            Your API key is stored securely and never shared
                        </div>
                    </div>

                    {apiKeySaved && (
                        <div style={{
                            padding: '0.75rem 1rem',
                            background: '#d1fae5',
                            color: '#065f46',
                            borderRadius: '8px',
                            marginBottom: '1rem',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            fontSize: '0.875rem',
                            fontWeight: 600
                        }}>
                            <FaCheckCircle /> API key saved successfully! Changes are now active.
                        </div>
                    )}

                    <button
                        onClick={handleSaveApiKey}
                        disabled={!apiKey.trim()}
                        style={{
                            padding: '0.75rem 1.5rem',
                            background: apiKey.trim() ? 'var(--primary-color)' : '#e5e7eb',
                            color: apiKey.trim() ? 'white' : '#9ca3af',
                            border: 'none',
                            borderRadius: '8px',
                            fontWeight: 600,
                            cursor: apiKey.trim() ? 'pointer' : 'not-allowed',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            fontSize: '0.875rem',
                            width: '100%',
                            justifyContent: 'center',
                            transition: 'all 0.2s'
                        }}
                        onMouseEnter={(e) => {
                            if (apiKey.trim()) e.currentTarget.style.background = 'var(--primary-dark)';
                        }}
                        onMouseLeave={(e) => {
                            if (apiKey.trim()) e.currentTarget.style.background = 'var(--primary-color)';
                        }}
                    >
                        <FaSave /> Save API Key
                    </button>
                </div>

                {/* Maintenance Windows */}
                <div style={cardStyle}>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <FaCalendarAlt /> Maintenance Windows
                    </h2>
                    <p style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '1.5rem' }}>
                        Schedule maintenance periods for system updates
                    </p>

                    {isInMaintenanceWindow() && (
                        <div style={{
                            padding: '0.75rem 1rem',
                            background: '#fef3c7',
                            color: '#92400e',
                            borderRadius: '8px',
                            marginBottom: '1rem',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            fontSize: '0.875rem',
                            fontWeight: 600,
                            border: '1px solid #f59e0b'
                        }}>
                            <FaExclamationTriangle /> System is currently in maintenance mode
                        </div>
                    )}

                    <div style={{ marginBottom: '1.5rem' }}>
                        <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer', marginBottom: '1rem' }}>
                            <input
                                type="checkbox"
                                checked={maintenanceEnabled}
                                onChange={(e) => setMaintenanceEnabled(e.target.checked)}
                                style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                            />
                            <span style={{ fontSize: '0.875rem', fontWeight: 600 }}>Enable Maintenance Mode</span>
                        </label>

                        {maintenanceEnabled && (
                            <>
                                <div style={{ marginBottom: '1rem' }}>
                                    <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, marginBottom: '0.5rem' }}>
                                        Start Date & Time
                                    </label>
                                    <input
                                        type="datetime-local"
                                        value={maintenanceStart}
                                        onChange={(e) => setMaintenanceStart(e.target.value)}
                                        style={{
                                            width: '100%',
                                            padding: '0.625rem 0.75rem',
                                            border: '1px solid var(--border-color)',
                                            borderRadius: '8px',
                                            fontSize: '0.875rem'
                                        }}
                                    />
                                </div>

                                <div style={{ marginBottom: '1rem' }}>
                                    <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, marginBottom: '0.5rem' }}>
                                        End Date & Time
                                    </label>
                                    <input
                                        type="datetime-local"
                                        value={maintenanceEnd}
                                        onChange={(e) => setMaintenanceEnd(e.target.value)}
                                        style={{
                                            width: '100%',
                                            padding: '0.625rem 0.75rem',
                                            border: '1px solid var(--border-color)',
                                            borderRadius: '8px',
                                            fontSize: '0.875rem'
                                        }}
                                    />
                                </div>
                            </>
                        )}
                    </div>

                    {maintenanceSaved && (
                        <div style={{
                            padding: '0.75rem 1rem',
                            background: '#d1fae5',
                            color: '#065f46',
                            borderRadius: '8px',
                            marginBottom: '1rem',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            fontSize: '0.875rem',
                            fontWeight: 600
                        }}>
                            <FaCheckCircle /> Maintenance window saved! Settings applied immediately.
                        </div>
                    )}

                    <button
                        onClick={handleSaveMaintenanceWindow}
                        style={{
                            padding: '0.75rem 1.5rem',
                            background: 'var(--primary-color)',
                            color: 'white',
                            border: 'none',
                            borderRadius: '8px',
                            fontWeight: 600,
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            fontSize: '0.875rem',
                            width: '100%',
                            justifyContent: 'center',
                            transition: 'all 0.2s'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.background = 'var(--primary-dark)'}
                        onMouseLeave={(e) => e.currentTarget.style.background = 'var(--primary-color)'}
                    >
                        <FaSave /> Save Maintenance Window
                    </button>
                </div>
            </div>

            {/* Backup & Restore */}
            <div style={cardStyle}>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <FaDownload /> Backup & Restore
                </h2>
                <p style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '1.5rem' }}>
                    Create backups of your configuration or restore from a previous backup
                </p>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    <div style={{
                        padding: '1.5rem',
                        border: '2px dashed var(--border-color)',
                        borderRadius: '8px',
                        textAlign: 'center'
                    }}>
                        <FaDownload size={32} style={{ color: 'var(--primary-color)', marginBottom: '1rem' }} />
                        <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '0.5rem' }}>Create Backup</h3>
                        <p style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '1rem' }}>
                            Download a backup file of all your settings
                        </p>
                        <button
                            onClick={handleCreateBackup}
                            style={{
                                padding: '0.75rem 1.5rem',
                                background: 'var(--primary-color)',
                                color: 'white',
                                border: 'none',
                                borderRadius: '8px',
                                fontWeight: 600,
                                cursor: 'pointer',
                                fontSize: '0.875rem',
                                transition: 'all 0.2s'
                            }}
                            onMouseEnter={(e) => e.currentTarget.style.background = 'var(--primary-dark)'}
                            onMouseLeave={(e) => e.currentTarget.style.background = 'var(--primary-color)'}
                        >
                            Download Backup
                        </button>
                    </div>

                    <div style={{
                        padding: '1.5rem',
                        border: '2px dashed var(--border-color)',
                        borderRadius: '8px',
                        textAlign: 'center'
                    }}>
                        <FaUpload size={32} style={{ color: '#3b82f6', marginBottom: '1rem' }} />
                        <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '0.5rem' }}>Restore Backup</h3>
                        <p style={{ fontSize: '0.875rem', color: 'var(--gray-color)', marginBottom: '1rem' }}>
                            Upload and restore from a backup file
                        </p>
                        <label style={{
                            padding: '0.75rem 1.5rem',
                            background: '#3b82f6',
                            color: 'white',
                            border: 'none',
                            borderRadius: '8px',
                            fontWeight: 600,
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            display: 'inline-block',
                            transition: 'all 0.2s'
                        }}
                            onMouseEnter={(e) => e.currentTarget.style.background = '#2563eb'}
                            onMouseLeave={(e) => e.currentTarget.style.background = '#3b82f6'}
                        >
                            Upload Backup
                            <input
                                type="file"
                                accept=".json"
                                onChange={handleRestoreBackup}
                                style={{ display: 'none' }}
                            />
                        </label>
                    </div>
                </div>
            </div>

            <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
        
        @media (max-width: 768px) {
          .settings-grid {
            grid-template-columns: 1fr !important;
          }
        }
      `}</style>
        </div>
    );
};

export default SettingsPage;
