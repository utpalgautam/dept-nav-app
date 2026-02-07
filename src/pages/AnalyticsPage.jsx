// src/pages/AnalyticsPage.jsx
import { useState } from 'react';
import Header from '../components/Header';
import {
    LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
    XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer
} from 'recharts';
import { FaUsers, FaSearch, FaMapMarkerAlt, FaArrowUp, FaDownload, FaCalendarAlt } from 'react-icons/fa';

const AnalyticsPage = () => {
    const [trendView, setTrendView] = useState('daily');

    // Key Metrics Data
    const keyMetrics = {
        totalUsers: { value: 1240, change: 5.2, trend: 'up', description: 'Total active users' },
        searchesToday: { value: 342, change: 12.4, trend: 'up', description: 'Searches performed today' },
        topLocation: { value: 'Main Library', count: 856, description: 'Most searched this week' }
    };

    // Weekly Report Summary
    const weeklyReport = {
        week: 'Feb 1 - Feb 7, 2026',
        totalSearches: 2847,
        totalNavigations: 1923,
        popularLocation: 'Main Library',
        peakDay: 'Tuesday',
        peakHour: '3:00 PM',
        changeFromLastWeek: 15.8
    };

    // Usage Trends Data
    const dailyTrends = [
        { name: 'Mon', searches: 420, navigations: 285 },
        { name: 'Tue', searches: 485, navigations: 340 },
        { name: 'Wed', searches: 398, navigations: 268 },
        { name: 'Thu', searches: 445, navigations: 312 },
        { name: 'Fri', searches: 520, navigations: 378 },
        { name: 'Sat', searches: 285, navigations: 180 },
        { name: 'Sun', searches: 294, navigations: 160 }
    ];

    const weeklyTrends = [
        { name: 'Week 1', searches: 2420, navigations: 1685 },
        { name: 'Week 2', searches: 2685, navigations: 1840 },
        { name: 'Week 3', searches: 2398, navigations: 1668 },
        { name: 'Week 4', searches: 2847, navigations: 1923 }
    ];

    const monthlyTrends = [
        { name: 'Oct', searches: 9850, navigations: 6720 },
        { name: 'Nov', searches: 10240, navigations: 7180 },
        { name: 'Dec', searches: 8650, navigations: 5940 },
        { name: 'Jan', searches: 11420, navigations: 7850 },
        { name: 'Feb', searches: 10350, navigations: 7196 }
    ];

    const getTrendData = () => {
        switch (trendView) {
            case 'daily': return dailyTrends;
            case 'weekly': return weeklyTrends;
            case 'monthly': return monthlyTrends;
            default: return dailyTrends;
        }
    };

    // Popular Locations Data
    const popularLocations = [
        { name: 'Main Library', searches: 856, percentage: 30 },
        { name: 'Science Lab A', searches: 642, percentage: 22.5 },
        { name: 'Student Union', searches: 485, percentage: 17 },
        { name: 'Cafeteria', searches: 398, percentage: 14 },
        { name: 'Admin Block', searches: 312, percentage: 11 },
        { name: 'Gym & Pool', searches: 254, percentage: 8.9 },
        { name: 'Lecture Hall 1', searches: 198, percentage: 6.9 },
        { name: 'Engineering Wing', searches: 165, percentage: 5.8 }
    ];

    // Location Heatmap Data
    const heatmapData = [
        { location: 'Library', mon: 85, tue: 92, wed: 78, thu: 88, fri: 95, sat: 45, sun: 38 },
        { location: 'Lab A', mon: 65, tue: 72, wed: 58, thu: 68, fri: 75, sat: 28, sun: 22 },
        { location: 'Union', mon: 45, tue: 52, wed: 48, thu: 55, fri: 68, sat: 42, sun: 35 },
        { location: 'Cafeteria', mon: 72, tue: 78, wed: 68, thu: 75, fri: 82, sat: 55, sun: 48 },
        { location: 'Gym', mon: 38, tue: 42, wed: 45, thu: 48, fri: 52, sat: 65, sun: 58 }
    ];

    // Peak Usage Times
    const peakUsageTimes = [
        { hour: '6 AM', searches: 12 },
        { hour: '7 AM', searches: 28 },
        { hour: '8 AM', searches: 65 },
        { hour: '9 AM', searches: 95 },
        { hour: '10 AM', searches: 118 },
        { hour: '11 AM', searches: 142 },
        { hour: '12 PM', searches: 156 },
        { hour: '1 PM', searches: 138 },
        { hour: '2 PM', searches: 165 },
        { hour: '3 PM', searches: 185 },
        { hour: '4 PM', searches: 158 },
        { hour: '5 PM', searches: 125 },
        { hour: '6 PM', searches: 88 },
        { hour: '7 PM', searches: 65 },
        { hour: '8 PM', searches: 42 },
        { hour: '9 PM', searches: 28 }
    ];

    // Category Distribution for Pie Chart
    const categoryDistribution = [
        { name: 'Academic Buildings', value: 45, color: '#84cc16' },
        { name: 'Recreation', value: 18, color: '#3b82f6' },
        { name: 'Dining', value: 15, color: '#f59e0b' },
        { name: 'Administrative', value: 12, color: '#8b5cf6' },
        { name: 'Other', value: 10, color: '#6b7280' }
    ];

    const getHeatmapColor = (value) => {
        if (value >= 80) return '#365314';
        if (value >= 60) return '#4d7c0f';
        if (value >= 40) return '#84cc16';
        if (value >= 20) return '#bef264';
        return '#ecfccb';
    };

    // Card style for consistency
    const cardStyle = {
        background: 'white',
        borderRadius: '12px',
        padding: '1.75rem',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05), 0 10px 25px -5px rgba(0, 0, 0, 0.05)',
        border: '1px solid #f0f0f0',
        transition: 'all 0.3s ease'
    };

    return (
        <div>
            <Header title="Analytics & Reports" />

            {/* Key Metrics Cards */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
                <div style={{ ...cardStyle, borderLeft: '4px solid var(--primary-color)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                        <div>
                            <h3 style={{ fontSize: '0.8rem', color: 'var(--gray-color)', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600 }}>Total Users</h3>
                            <div style={{ fontSize: '2.25rem', fontWeight: 700, color: 'var(--dark-color)', marginBottom: '0.5rem' }}>{keyMetrics.totalUsers.value.toLocaleString()}</div>
                        </div>
                        <div style={{ background: 'linear-gradient(135deg, #84cc16 0%, #a3e635 100%)', color: 'white', padding: '0.875rem', borderRadius: '12px', boxShadow: '0 4px 12px rgba(132, 204, 22, 0.25)' }}>
                            <FaUsers size={24} />
                        </div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', paddingTop: '0.75rem', borderTop: '1px solid #f0f0f0' }}>
                        <span style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--success-color)', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                            <FaArrowUp size={12} /> {keyMetrics.totalUsers.change}%
                        </span>
                        <span style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>{keyMetrics.totalUsers.description}</span>
                    </div>
                </div>

                <div style={{ ...cardStyle, borderLeft: '4px solid #3b82f6' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                        <div>
                            <h3 style={{ fontSize: '0.8rem', color: 'var(--gray-color)', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600 }}>Searches Today</h3>
                            <div style={{ fontSize: '2.25rem', fontWeight: 700, color: 'var(--dark-color)', marginBottom: '0.5rem' }}>{keyMetrics.searchesToday.value}</div>
                        </div>
                        <div style={{ background: 'linear-gradient(135deg, #3b82f6 0%, #60a5fa 100%)', color: 'white', padding: '0.875rem', borderRadius: '12px', boxShadow: '0 4px 12px rgba(59, 130, 246, 0.25)' }}>
                            <FaSearch size={24} />
                        </div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', paddingTop: '0.75rem', borderTop: '1px solid #f0f0f0' }}>
                        <span style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--success-color)', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                            <FaArrowUp size={12} /> {keyMetrics.searchesToday.change}%
                        </span>
                        <span style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>{keyMetrics.searchesToday.description}</span>
                    </div>
                </div>

                <div style={{ ...cardStyle, borderLeft: '4px solid #f59e0b' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                        <div>
                            <h3 style={{ fontSize: '0.8rem', color: 'var(--gray-color)', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600 }}>Top Location</h3>
                            <div style={{ fontSize: '1.75rem', fontWeight: 700, color: 'var(--dark-color)', marginBottom: '0.5rem' }}>{keyMetrics.topLocation.value}</div>
                        </div>
                        <div style={{ background: 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)', color: 'white', padding: '0.875rem', borderRadius: '12px', boxShadow: '0 4px 12px rgba(245, 158, 11, 0.25)' }}>
                            <FaMapMarkerAlt size={24} />
                        </div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', paddingTop: '0.75rem', borderTop: '1px solid #f0f0f0' }}>
                        <span style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--dark-color)' }}>{keyMetrics.topLocation.count} searches</span>
                        <span style={{ fontSize: '0.875rem', color: 'var(--gray-color)' }}>• {keyMetrics.topLocation.description}</span>
                    </div>
                </div>
            </div>

            {/* Weekly Report Card */}
            <div style={{ ...cardStyle, background: 'linear-gradient(135deg, #84cc16 0%, #65a30d 100%)', color: 'white', marginBottom: '2rem', boxShadow: '0 10px 40px -10px rgba(132, 204, 22, 0.35)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                    <div>
                        <h2 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                            <FaCalendarAlt /> Weekly Report
                        </h2>
                        <p style={{ opacity: 0.9, fontSize: '0.95rem', fontWeight: 500 }}>{weeklyReport.week}</p>
                    </div>
                    <button style={{ background: 'white', color: 'var(--primary-dark)', fontWeight: 600, padding: '0.75rem 1.5rem', borderRadius: '8px', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.5rem', boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)', transition: 'all 0.2s' }}
                        onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-2px)'}
                        onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}>
                        <FaDownload /> Generate Report
                    </button>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1.5rem' }}>
                    <div style={{ background: 'rgba(255, 255, 255, 0.15)', backdropFilter: 'blur(10px)', padding: '1.25rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.2)' }}>
                        <div style={{ fontSize: '0.875rem', opacity: 0.9, marginBottom: '0.5rem', fontWeight: 500 }}>Total Searches</div>
                        <div style={{ fontSize: '2.25rem', fontWeight: 700 }}>{weeklyReport.totalSearches.toLocaleString()}</div>
                    </div>
                    <div style={{ background: 'rgba(255, 255, 255, 0.15)', backdropFilter: 'blur(10px)', padding: '1.25rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.2)' }}>
                        <div style={{ fontSize: '0.875rem', opacity: 0.9, marginBottom: '0.5rem', fontWeight: 500 }}>Total Navigations</div>
                        <div style={{ fontSize: '2.25rem', fontWeight: 700 }}>{weeklyReport.totalNavigations.toLocaleString()}</div>
                    </div>
                    <div style={{ background: 'rgba(255, 255, 255, 0.15)', backdropFilter: 'blur(10px)', padding: '1.25rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.2)' }}>
                        <div style={{ fontSize: '0.875rem', opacity: 0.9, marginBottom: '0.5rem', fontWeight: 500 }}>Most Popular</div>
                        <div style={{ fontSize: '1.5rem', fontWeight: 700 }}>{weeklyReport.popularLocation}</div>
                    </div>
                    <div style={{ background: 'rgba(255, 255, 255, 0.15)', backdropFilter: 'blur(10px)', padding: '1.25rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.2)' }}>
                        <div style={{ fontSize: '0.875rem', opacity: 0.9, marginBottom: '0.5rem', fontWeight: 500 }}>Peak Time</div>
                        <div style={{ fontSize: '1.25rem', fontWeight: 700 }}>{weeklyReport.peakDay}, {weeklyReport.peakHour}</div>
                    </div>
                    <div style={{ background: 'rgba(255, 255, 255, 0.15)', backdropFilter: 'blur(10px)', padding: '1.25rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.2)' }}>
                        <div style={{ fontSize: '0.875rem', opacity: 0.9, marginBottom: '0.5rem', fontWeight: 500 }}>Week-over-Week</div>
                        <div style={{ fontSize: '1.75rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <FaArrowUp /> +{weeklyReport.changeFromLastWeek}%
                        </div>
                    </div>
                </div>
            </div>

            {/* Charts Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '2rem' }} className="analytics-chart-grid">
                {/* Usage Trends Card */}
                <div style={cardStyle}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                        <h3 style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--dark-color)' }}>Usage Trends</h3>
                        <div style={{ display: 'flex', gap: '0.375rem', background: '#f3f4f6', padding: '0.25rem', borderRadius: '8px' }}>
                            <button
                                onClick={() => setTrendView('daily')}
                                style={{
                                    padding: '0.5rem 1rem',
                                    borderRadius: '6px',
                                    border: 'none',
                                    background: trendView === 'daily' ? 'var(--primary-color)' : 'transparent',
                                    color: trendView === 'daily' ? 'white' : 'var(--gray-color)',
                                    fontSize: '0.8rem',
                                    fontWeight: 600,
                                    cursor: 'pointer',
                                    transition: 'all 0.2s'
                                }}
                            >
                                Daily
                            </button>
                            <button
                                onClick={() => setTrendView('weekly')}
                                style={{
                                    padding: '0.5rem 1rem',
                                    borderRadius: '6px',
                                    border: 'none',
                                    background: trendView === 'weekly' ? 'var(--primary-color)' : 'transparent',
                                    color: trendView === 'weekly' ? 'white' : 'var(--gray-color)',
                                    fontSize: '0.8rem',
                                    fontWeight: 600,
                                    cursor: 'pointer',
                                    transition: 'all 0.2s'
                                }}
                            >
                                Weekly
                            </button>
                            <button
                                onClick={() => setTrendView('monthly')}
                                style={{
                                    padding: '0.5rem 1rem',
                                    borderRadius: '6px',
                                    border: 'none',
                                    background: trendView === 'monthly' ? 'var(--primary-color)' : 'transparent',
                                    color: trendView === 'monthly' ? 'white' : 'var(--gray-color)',
                                    fontSize: '0.8rem',
                                    fontWeight: 600,
                                    cursor: 'pointer',
                                    transition: 'all 0.2s'
                                }}
                            >
                                Monthly
                            </button>
                        </div>
                    </div>
                    <ResponsiveContainer width="100%" height={280}>
                        <LineChart data={getTrendData()}>
                            <defs>
                                <linearGradient id="searchGradient" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#84cc16" stopOpacity={0.2} />
                                    <stop offset="95%" stopColor="#84cc16" stopOpacity={0} />
                                </linearGradient>
                                <linearGradient id="navGradient" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.2} />
                                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                            <XAxis dataKey="name" tick={{ fontSize: 12, fill: '#6b7280', fontWeight: 500 }} axisLine={false} tickLine={false} />
                            <YAxis tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                            <Tooltip
                                contentStyle={{
                                    borderRadius: '10px',
                                    border: 'none',
                                    boxShadow: '0 10px 30px rgba(0, 0, 0, 0.15)',
                                    padding: '12px'
                                }}
                            />
                            <Legend wrapperStyle={{ fontSize: '13px', paddingTop: '15px', fontWeight: 600 }} />
                            <Line type="monotone" dataKey="searches" stroke="#84cc16" strokeWidth={3} dot={{ r: 5, strokeWidth: 2, fill: 'white' }} activeDot={{ r: 7 }} />
                            <Line type="monotone" dataKey="navigations" stroke="#3b82f6" strokeWidth={3} dot={{ r: 5, strokeWidth: 2, fill: 'white' }} activeDot={{ r: 7 }} />
                        </LineChart>
                    </ResponsiveContainer>
                </div>

                {/* Category Distribution Card */}
                <div style={cardStyle}>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--dark-color)', marginBottom: '1.5rem' }}>Search Distribution by Category</h3>
                    <ResponsiveContainer width="100%" height={280}>
                        <PieChart>
                            <Pie
                                data={categoryDistribution}
                                cx="50%"
                                cy="50%"
                                labelLine={false}
                                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                                outerRadius={90}
                                fill="#8884d8"
                                dataKey="value"
                                strokeWidth={2}
                                stroke="#fff"
                            >
                                {categoryDistribution.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={entry.color} />
                                ))}
                            </Pie>
                            <Tooltip contentStyle={{ borderRadius: '10px', border: 'none', boxShadow: '0 10px 30px rgba(0, 0, 0, 0.15)' }} />
                        </PieChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Popular Locations Card */}
            <div style={{ ...cardStyle, marginBottom: '2rem' }}>
                <h3 style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--dark-color)', marginBottom: '1.5rem' }}>Most Searched Locations This Week</h3>
                <ResponsiveContainer width="100%" height={340}>
                    <BarChart data={popularLocations} layout="vertical" margin={{ left: 110 }}>
                        <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#e5e7eb" />
                        <XAxis type="number" tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                        <YAxis
                            type="category"
                            dataKey="name"
                            tick={{ fontSize: 12, fill: '#374151', fontWeight: 600 }}
                            axisLine={false}
                            tickLine={false}
                            width={100}
                        />
                        <Tooltip
                            contentStyle={{ borderRadius: '10px', border: 'none', boxShadow: '0 10px 30px rgba(0, 0, 0, 0.15)', padding: '12px' }}
                            formatter={(value, name, props) => [`${value} searches (${props.payload.percentage}%)`, 'Searches']}
                        />
                        <Bar dataKey="searches" radius={[0, 8, 8, 0]} barSize={28}>
                            {popularLocations.map((entry, index) => (
                                <Cell key={`cell-${index}`} fill={index === 0 ? '#65a30d' : index < 3 ? '#84cc16' : '#a3e635'} />
                            ))}
                        </Bar>
                    </BarChart>
                </ResponsiveContainer>
            </div>

            {/* Location Heatmap Card */}
            <div style={{ ...cardStyle, marginBottom: '2rem' }}>
                <h3 style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--dark-color)', marginBottom: '1.5rem' }}>Location Popularity Heatmap (by Day)</h3>
                <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '6px' }}>
                        <thead>
                            <tr>
                                <th style={{ textAlign: 'left', padding: '0.875rem', fontSize: '0.75rem', fontWeight: 700, color: 'var(--gray-color)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Location</th>
                                {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => (
                                    <th key={day} style={{ textAlign: 'center', padding: '0.875rem', fontSize: '0.75rem', fontWeight: 700, color: 'var(--gray-color)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{day}</th>
                                ))}
                            </tr>
                        </thead>
                        <tbody>
                            {heatmapData.map((row, index) => (
                                <tr key={index}>
                                    <td style={{ padding: '0.625rem', fontWeight: 700, fontSize: '0.9rem', color: 'var(--dark-color)' }}>{row.location}</td>
                                    {['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].map((day) => (
                                        <td
                                            key={day}
                                            style={{
                                                textAlign: 'center',
                                                padding: '1.125rem',
                                                background: getHeatmapColor(row[day]),
                                                color: row[day] >= 60 ? 'white' : '#365314',
                                                fontWeight: 700,
                                                fontSize: '0.9rem',
                                                borderRadius: '8px',
                                                cursor: 'pointer',
                                                transition: 'all 0.2s',
                                                boxShadow: '0 2px 4px rgba(0, 0, 0, 0.05)'
                                            }}
                                            onMouseEnter={(e) => {
                                                e.currentTarget.style.transform = 'scale(1.1)';
                                                e.currentTarget.style.boxShadow = '0 6px 12px rgba(0, 0, 0, 0.15)';
                                                e.currentTarget.style.zIndex = '10';
                                            }}
                                            onMouseLeave={(e) => {
                                                e.currentTarget.style.transform = 'scale(1)';
                                                e.currentTarget.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.05)';
                                                e.currentTarget.style.zIndex = '1';
                                            }}
                                        >
                                            {row[day]}
                                        </td>
                                    ))}
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
                <div style={{ marginTop: '1.25rem', display: 'flex', alignItems: 'center', gap: '1.5rem', fontSize: '0.8rem', color: 'var(--gray-color)', paddingTop: '1rem', borderTop: '1px solid #f0f0f0' }}>
                    <span style={{ fontWeight: 700, color: 'var(--dark-color)' }}>Intensity Scale:</span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
                        <div style={{ width: '36px', height: '24px', background: '#ecfccb', borderRadius: '6px', border: '1px solid #d9f99d' }}></div>
                        <span style={{ fontWeight: 600 }}>Low</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
                        <div style={{ width: '36px', height: '24px', background: '#84cc16', borderRadius: '6px' }}></div>
                        <span style={{ fontWeight: 600 }}>Medium</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
                        <div style={{ width: '36px', height: '24px', background: '#365314', borderRadius: '6px' }}></div>
                        <span style={{ fontWeight: 600 }}>High</span>
                    </div>
                </div>
            </div>

            {/* Peak Usage Times Card */}
            <div style={cardStyle}>
                <h3 style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--dark-color)', marginBottom: '1.5rem' }}>Peak Usage Times (Hourly)</h3>
                <ResponsiveContainer width="100%" height={320}>
                    <BarChart data={peakUsageTimes}>
                        <defs>
                            <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="0%" stopColor="#84cc16" stopOpacity={1} />
                                <stop offset="100%" stopColor="#a3e635" stopOpacity={0.8} />
                            </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                        <XAxis
                            dataKey="hour"
                            tick={{ fontSize: 11, fill: '#6b7280', fontWeight: 500 }}
                            axisLine={false}
                            tickLine={false}
                            angle={-45}
                            textAnchor="end"
                            height={80}
                        />
                        <YAxis tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                        <Tooltip
                            contentStyle={{
                                borderRadius: '10px',
                                border: 'none',
                                boxShadow: '0 10px 30px rgba(0, 0, 0, 0.15)',
                                padding: '12px'
                            }}
                        />
                        <Bar dataKey="searches" radius={[8, 8, 0, 0]} barSize={35}>
                            {peakUsageTimes.map((entry, index) => {
                                const isHighPeak = entry.searches >= 150;
                                return <Cell key={`cell-${index}`} fill={isHighPeak ? '#65a30d' : 'url(#barGradient)'} />;
                            })}
                        </Bar>
                    </BarChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
};

export default AnalyticsPage;
