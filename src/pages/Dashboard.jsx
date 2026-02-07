// src/pages/Dashboard.jsx
import Header from '../components/Header';
import DashboardCards from '../components/DashboardCards';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell, CartesianGrid } from 'recharts';
import { FaEllipsisH } from 'react-icons/fa';

const Dashboard = () => {
  const recentActivity = [
    {
      action: 'New Route Created',
      description: 'Engineering Hall → Lab 48',
      status: 'LIVE',
      time: '2 mins ago'
    },
    {
      action: 'New User Joined',
      description: 'Faculty of Humanities',
      status: 'VERIFIED',
      time: '14 mins ago'
    },
    {
      action: 'Building Info Updated',
      description: 'Main Library (South Wing)',
      status: 'PENDING',
      time: '45 mins ago'
    },
    {
      action: 'System Maintenance',
      description: 'Server patching scheduled',
      status: 'SCHEDULED',
      time: '2 hours ago'
    }
  ];

  const chartData = [
    { name: 'MAIN LIBRARY', value: 85 },
    { name: 'SCIENCE LAB A', value: 65 },
    { name: 'STUDENT UNION', value: 45 },
    { name: 'CAFETERIA', value: 38 },
    { name: 'ADMIN BLOCK', value: 30 },
    { name: 'GYM & POOL', value: 25 },
    { name: 'LECTURE HALL 1', value: 20 },
  ];

  const getStatusStyle = (status) => {
    switch (status) {
      case 'LIVE': return 'status-available';
      case 'VERIFIED': return 'status-inclass'; // Using existing class for blue-ish look or modify CSS
      case 'PENDING': return 'status-offsite';
      default: return '';
    }
  };

  return (
    <div>
      <Header title="Dashboard Overview" />

      <DashboardCards />

      <div className="card mb-6" style={{ marginBottom: '2rem', padding: '1.5rem', background: 'white', borderRadius: '0.5rem', boxShadow: 'var(--shadow)', border: '1px solid var(--border-color)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
          <h2 style={{ fontSize: '1.125rem', fontWeight: 600 }}>Popular Destinations</h2>
          <select className="form-control" style={{ width: 'auto' }}>
            <option>Last 30 Days</option>
            <option>Last 7 Days</option>
            <option>Last 24 Hours</option>
          </select>
        </div>
        <div style={{ height: 300 }}>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
              <defs>
                <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="var(--primary-color)" stopOpacity={0.8} />
                  <stop offset="95%" stopColor="var(--primary-color)" stopOpacity={0.3} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
              <XAxis
                dataKey="name"
                axisLine={false}
                tickLine={false}
                tick={{ fontSize: 11, fill: '#64748b', fontWeight: 500 }}
                interval={0}
                dy={10}
              />
              <YAxis
                axisLine={false}
                tickLine={false}
                tick={{ fontSize: 11, fill: '#64748b' }}
              />
              <Tooltip
                cursor={{ fill: '#f8fafc' }}
                contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)' }}
              />
              <Bar dataKey="value" radius={[6, 6, 0, 0]} barSize={50} fill="url(#colorValue)">
                {chartData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={index === 0 ? 'var(--primary-dark)' : 'url(#colorValue)'} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="card" style={{ padding: '1.5rem', background: 'white', borderRadius: '0.5rem', boxShadow: 'var(--shadow)', border: '1px solid var(--border-color)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
          <h2 style={{ fontSize: '1.125rem', fontWeight: 600 }}>Recent Activity</h2>
          <button className="btn btn-outline" style={{ fontSize: '0.875rem' }}>View All History</button>
        </div>

        <table className="table" style={{ width: '100%' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--border-color)' }}>
              <th style={{ textAlign: 'left', paddingBottom: '1rem', color: 'var(--muted-gray)', fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase' }}>Action</th>
              <th style={{ textAlign: 'left', paddingBottom: '1rem', color: 'var(--muted-gray)', fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase' }}>Department / Facility</th>
              <th style={{ textAlign: 'left', paddingBottom: '1rem', color: 'var(--muted-gray)', fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase' }}>Status</th>
              <th style={{ textAlign: 'left', paddingBottom: '1rem', color: 'var(--muted-gray)', fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase' }}>Time</th>
              <th style={{ textAlign: 'right', paddingBottom: '1rem', color: 'var(--muted-gray)', fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase' }}>Details</th>
            </tr>
          </thead>
          <tbody>
            {recentActivity.map((activity, index) => (
              <tr key={index} style={{ borderBottom: index === recentActivity.length - 1 ? 'none' : '1px solid var(--border-color)' }}>
                <td style={{ padding: '1rem 0', fontWeight: 600 }}>{activity.action}</td>
                <td style={{ padding: '1rem 0', color: 'var(--gray-color)' }}>{activity.description}</td>
                <td style={{ padding: '1rem 0' }}>
                  <span className={`status-badge ${getStatusStyle(activity.status)}`}>
                    {activity.status}
                  </span>
                </td>
                <td style={{ padding: '1rem 0', color: 'var(--gray-color)', fontSize: '0.875rem' }}>{activity.time}</td>
                <td style={{ padding: '1rem 0', textAlign: 'right', color: 'var(--muted-gray)' }}>
                  <FaEllipsisH style={{ cursor: 'pointer' }} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};


export default Dashboard;