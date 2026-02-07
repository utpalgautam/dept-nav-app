// src/components/DashboardCards.jsx
import { FaArrowUp, FaArrowDown } from 'react-icons/fa';

const DashboardCards = () => {
  const stats = [
    {
      title: 'Total Users',
      value: '1,240',
      change: '+5.2%',
      positive: true,
      description: 'Active in the last 30 days'
    },
    {
      title: 'Total Buildings',
      value: '12',
      change: '0%',
      positive: true,
      description: 'All sections open almost'
    },
    {
      title: 'Navigation Requests',
      value: '8,432',
      change: '+12.4%',
      positive: true,
      description: 'Request period: Tuesday 3 PM'
    }
  ];

  return (
    <div className="stats-grid">
      {stats.map((stat, index) => (
        <div key={index} className="stat-card" style={{ borderTop: `4px solid ${index === 0 ? 'var(--primary-color)' : index === 1 ? '#f59e0b' : '#3b82f6'}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.5rem' }}>
            <h3>{stat.title}</h3>
            {index === 0 && <div style={{ background: '#ecfccb', color: '#3f6212', padding: '0.25rem', borderRadius: '4px' }}><FaArrowUp size={12} /></div>}
            {index === 1 && <div style={{ background: '#fef3c7', color: '#92400e', padding: '0.25rem', borderRadius: '4px' }}><FaArrowUp size={12} /></div>}
            {index === 2 && <div style={{ background: '#dbeafe', color: '#1e40af', padding: '0.25rem', borderRadius: '4px' }}><FaArrowUp size={12} /></div>}
          </div>
          <div className="stat-number">{stat.value}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.5rem' }}>
            <span className={`stat-change ${stat.positive ? 'positive' : 'negative'}`} style={{ fontSize: '0.75rem', fontWeight: 700 }}>
              {stat.change}
            </span>
            <span style={{ fontSize: '0.75rem', color: 'var(--gray-color)' }}>{stat.description}</span>
          </div>
        </div>
      ))}
    </div>
  );
};

export default DashboardCards;