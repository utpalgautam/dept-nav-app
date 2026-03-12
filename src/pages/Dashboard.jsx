import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FaSearch, FaBuilding, FaUsers, FaFlask } from 'react-icons/fa';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { db } from '../services/firebaseConfig';
import { collection, getDocs } from 'firebase/firestore';
import { getSearchesPerBuilding, getSearchesPerDay } from '../services/analyticsService';
import Header from '../components/Header';

const Dashboard = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [summaryData, setSummaryData] = useState([]);
  const [searchesByBuilding, setSearchesByBuilding] = useState([]);
  const [searchesPerDay, setSearchesPerDay] = useState([]);
  const [timeframe, setTimeframe] = useState('week');

  useEffect(() => {
    const fetchCounts = async () => {
      try {
        setLoading(true);
        const [buildingsSnap, facultySnap, hallsSnap, labsSnap] = await Promise.all([
          getDocs(collection(db, 'buildings')),
          getDocs(collection(db, 'faculty')),
          getDocs(collection(db, 'halls')),
          getDocs(collection(db, 'labs'))
        ]);

        setSummaryData([
          { label: 'Total Buildings', count: buildingsSnap.size, icon: <FaBuilding /> },
          { label: 'Total Faculty', count: facultySnap.size, icon: <FaUsers /> },
          { label: 'Total Halls/Labs', count: hallsSnap.size + labsSnap.size, icon: <FaFlask /> },
        ]);

        const allBuildings = buildingsSnap.docs.map(doc => doc.data().name);
        const searchResults = await getSearchesPerBuilding(timeframe);
        
        // Merge: ensure all buildings from database are shown
        const mergedBuildingData = allBuildings.map(name => {
          const match = searchResults.find(r => r.name === name);
          return { name, searches: match ? match.searches : 0 };
        }).sort((a, b) => b.searches - a.searches);

        setSearchesByBuilding(mergedBuildingData);

        const searchesDayData = await getSearchesPerDay(7);
        setSearchesPerDay(searchesDayData);

      } catch (error) {
        console.error("Error fetching dashboard data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchCounts();
  }, [timeframe]);

  const quickActions = [
    {
      label: 'Add Faculty', sub: 'Nearby', path: '/faculties',
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
          <circle cx="9" cy="7" r="4" />
          <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
          <path d="M16 3.13a4 4 0 0 1 0 7.75" />
        </svg>
      )
    },
    {
      label: 'Add Building', sub: 'Nearby', path: '/buildings',
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <rect x="4" y="2" width="16" height="20" rx="1" />
          <path d="M8 6h.01" />
          <path d="M16 6h.01" />
          <path d="M8 10h.01" />
          <path d="M16 10h.01" />
          <path d="M8 14h.01" />
          <path d="M16 14h.01" />
          <path d="M8 18h.01" />
          <path d="M16 18h.01" />
        </svg>
      )
    },
    {
      label: 'Add Halls/Labs', sub: 'Nearby', path: '/halls-labs',
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M10 2v7.3l-4.7 9.5A2 2 0 0 0 7 22h10a2 2 0 0 0 1.7-3.2L14 9.3V2" />
          <path d="M8.5 2h7" />
          <path d="M7 16h10" />
        </svg>
      )
    },
    {
      label: 'Add User', sub: 'Nearby', path: '/users',
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
          <circle cx="12" cy="7" r="4" />
        </svg>
      )
    },
  ];

  return (
    <div className="db-page">
      <Header title="Dashboard" searchDisabled={true} />

      {/* Stats Row */}
      <div className="db-stats-row">
        {/* Welcome Card */}
        <div className="db-welcome-card">
          <div className="db-card-circle-bg"></div>
          <div className="db-welcome-content">
            <div className="db-welcome-emoji">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M19.56 12C19.56 12.82 19.34 13.59 18.96 14.26C18.66 14.8 18.25 15.26 17.76 15.62C17.27 15.98 16.71 16.23 16.11 16.36C15.51 16.49 14.88 16.5 14.25 16.4C13.62 16.3 13.01 16.09 12.46 15.78L10.5 14.5L8.54 13.22C7.99 12.91 7.38 12.7 6.75 12.6C6.12 12.5 5.49 12.51 4.89 12.64C4.29 12.77 3.73 13.02 3.24 13.38C2.75 13.74 2.34 14.2 2.04 14.74C1.66 15.41 1.44 16.18 1.44 17C1.44 19.43 3.41 21.4 5.84 21.4H13.84C17.15 21.4 19.84 18.71 19.84 15.4C19.84 14.39 19.59 13.44 19.14 12.61L19.56 12Z" fill="black" />
                <path d="M7 10C7.55 10 8 9.55 8 9V4C8 3.45 7.55 3 7 3C6.45 3 6 3.45 6 4V9C6 9.55 6.45 10 7 10Z" fill="black" />
                <path d="M11 9C11.55 9 12 8.55 12 8V3C12 2.45 11.55 2 11 2C10.45 2 10 2.45 10 3V8C10 8.55 10.45 9 11 9Z" fill="black" />
                <path d="M15 10C15.55 10 16 9.55 16 9V4C16 3.45 15.55 3 15 3C14.45 3 14 3.45 14 4V9C14 9.55 14.45 10 15 10Z" fill="black" />
                <path d="M19 12C19.55 12 20 11.55 20 11V6C20 5.45 19.55 5 19 5C18.45 5 18 5.45 18 6V11C18 11.55 18.45 12 19 12Z" fill="black" />
              </svg>
            </div>
            <h2>Welcome, Utpal</h2>
            <p>System is active and stable.</p>
          </div>
        </div>

        {/* Render Summary Data Cards */}
        <div className="db-stat-card db-stat-purple">
          <div className="db-stat-icon"><FaUsers color="#000" /></div>
          <div className="db-stat-number">{loading ? '—' : (summaryData[1]?.count || '124')}</div>
          <div className="db-stat-label">Total Faculty</div>
        </div>
        <div className="db-stat-card db-stat-green">
          <div className="db-stat-icon"><FaBuilding color="#000" /></div>
          <div className="db-stat-number">{loading ? '—' : (summaryData[0]?.count || '45')}</div>
          <div className="db-stat-label">Total Buildings</div>
        </div>
        <div className="db-stat-card db-stat-beige">
          <div className="db-stat-icon"><FaFlask color="#000" /></div>
          <div className="db-stat-number">{loading ? '—' : (summaryData[2]?.count || '18')}</div>
          <div className="db-stat-label">Total Labs/Hall</div>
        </div>
      </div>

      {/* Quick Actions Grid Structure from Image 2 */}
      <h3 className="db-section-title">Quick Actions</h3>
      <div className="db-actions-grid">
        {/* Row 1, Column 1 */}
        <div className="db-action-card" onClick={() => navigate('/faculties', { state: { openForm: true } })}>
          <div className="db-action-icon-wrapper"><div className="db-action-icon-circle">{quickActions[0].icon}</div></div>
          <div className="db-action-text"><span className="db-action-sub">Nearby</span><span className="db-action-label">Add Faculty</span></div>
        </div>
        {/* Row 1, Column 2 */}
        <div className="db-action-card" onClick={() => navigate('/buildings', { state: { openForm: true } })}>
          <div className="db-action-icon-wrapper"><div className="db-action-icon-circle">{quickActions[1].icon}</div></div>
          <div className="db-action-text"><span className="db-action-sub">Nearby</span><span className="db-action-label">Add Building</span></div>
        </div>
        {/* Row 1, Column 3 */}
        <div className="db-action-card" onClick={() => navigate('/halls-labs', { state: { openForm: true } })}>
          <div className="db-action-icon-wrapper"><div className="db-action-icon-circle">{quickActions[2].icon}</div></div>
          <div className="db-action-text"><span className="db-action-sub">Nearby</span><span className="db-action-label">Add Halls/Labs</span></div>
        </div>

        {/* Vertical Spanning Block - Column 4, now Searches by Building */}
        <div className="db-placeholder-block grid-span-2-row">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
            <span className="db-block-title" style={{ margin: 0 }}>Searches by Building</span>
            <select 
              value={timeframe} 
              onChange={(e) => setTimeframe(e.target.value)}
              className="db-filter-select"
              style={{
                background: '#1c1c1e',
                color: '#888',
                border: '1px solid #333',
                borderRadius: '6px',
                fontSize: '10px',
                padding: '2px 4px',
                outline: 'none',
                cursor: 'pointer'
              }}
            >
              <option value="day">Day</option>
              <option value="week">Week</option>
              <option value="month">Month</option>
            </select>
          </div>
          <div style={{ width: '100%', height: 'calc(100% - 30px)' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={searchesByBuilding} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#333" />
                <XAxis type="number" hide />
                <YAxis dataKey="name" type="category" axisLine={false} tickLine={false} tick={{ fontSize: 9, fill: '#888' }} width={70} />
                <Tooltip
                  cursor={{ fill: 'rgba(255,255,255,0.05)' }}
                  contentStyle={{ background: '#1c1c1e', border: '1px solid #444', borderRadius: '8px', color: '#fff' }}
                />
                <Bar dataKey="searches" fill="#818cf8" radius={[0, 4, 4, 0]} barSize={12} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Row 2, Column 1 */}
        <div className="db-action-card" onClick={() => navigate('/users', { state: { openForm: true } })}>
          <div className="db-action-icon-wrapper"><div className="db-action-icon-circle">{quickActions[3].icon}</div></div>
          <div className="db-action-text"><span className="db-action-sub">Manage</span><span className="db-action-label">Add User</span></div>
        </div>

        {/* Horizontal Spanning Block - Row 2, now Searches per Day as LineChart */}
        <div className="db-placeholder-block grid-span-2-col">
          <span className="db-block-title">Searches per Day</span>
          <div style={{ width: '100%', height: 'calc(100% - 20px)' }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={searchesPerDay} margin={{ top: 5, right: 20, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#333" />
                <XAxis 
                  dataKey="name" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 9, fill: '#888' }} 
                />
                <YAxis 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 9, fill: '#888' }} 
                />
                <Tooltip
                  contentStyle={{ background: '#1c1c1e', border: '1px solid #444', borderRadius: '8px', color: '#fff', fontSize: '10px' }}
                  itemStyle={{ color: '#818cf8' }}
                />
                <Line 
                    type="monotone" 
                    dataKey="searches" 
                    stroke="#818cf8" 
                    strokeWidth={3} 
                    dot={{ r: 3, fill: '#818cf8', strokeWidth: 0 }} 
                    activeDot={{ r: 5, strokeWidth: 0 }} 
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
