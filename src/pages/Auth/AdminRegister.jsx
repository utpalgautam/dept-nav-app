// src/pages/Auth/AdminRegister.jsx
import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { registerAdmin } from '../../services/authService';
import '../../styles/auth.css';

const AdminIllustration = () => (
    <svg viewBox="0 0 380 320" fill="none" xmlns="http://www.w3.org/2000/svg" className="auth-illustration">
        {/* Big gear */}
        <g transform="translate(185, 210)">
            <circle cx="0" cy="0" r="55" fill="#3a3a3a"/>
            <circle cx="0" cy="0" r="35" fill="#2a2a2a"/>
            <circle cx="0" cy="0" r="18" fill="#484848"/>
            {/* Gear teeth */}
            {[0, 45, 90, 135, 180, 225, 270, 315].map((angle, i) => (
                <rect
                    key={i}
                    x="-7" y="-62" width="14" height="14"
                    rx="3"
                    fill="#3a3a3a"
                    transform={`rotate(${angle})`}
                />
            ))}
        </g>

        {/* Laptop / person working */}
        <g transform="translate(155, 120)">
            {/* Body */}
            <ellipse cx="30" cy="60" rx="22" ry="28" fill="#888"/>
            {/* Head */}
            <circle cx="30" cy="18" r="20" fill="#aaa"/>
            {/* Laptop */}
            <rect x="-10" y="70" width="80" height="50" rx="6" fill="#555"/>
            <rect x="-5" y="75" width="70" height="40" rx="4" fill="#3a3a3a"/>
            {/* Screen glow lines */}
            <rect x="5" y="85" width="40" height="3" rx="1.5" fill="#777"/>
            <rect x="5" y="93" width="30" height="3" rx="1.5" fill="#666"/>
            <rect x="5" y="101" width="35" height="3" rx="1.5" fill="#666"/>
            {/* Arm extended */}
            <line x1="52" y1="50" x2="90" y2="20" stroke="#777" strokeWidth="5" strokeLinecap="round"/>
            <line x1="90" y1="20" x2="100" y2="5" stroke="#888" strokeWidth="4" strokeLinecap="round"/>
            {/* Wave hand */}
            <ellipse cx="103" cy="2" rx="10" ry="8" fill="#aaa" transform="rotate(-20, 103, 2)"/>
        </g>

        {/* Floating UI elements - top left */}
        <rect x="50" y="60" width="50" height="40" rx="6" fill="#444" opacity="0.8"/>
        <rect x="58" y="70" width="30" height="4" rx="2" fill="#777"/>
        <rect x="58" y="79" width="22" height="4" rx="2" fill="#666"/>

        {/* Check circle */}
        <circle cx="100" cy="55" r="18" fill="#3a3a3a" opacity="0.9"/>
        <path d="M92 55 L98 62 L110 48" stroke="#bbb" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none"/>

        {/* Avatar circle */}
        <circle cx="298" cy="75" r="22" fill="#3a3a3a" opacity="0.9"/>
        <circle cx="298" cy="70" r="10" fill="#777"/>
        <ellipse cx="298" cy="90" rx="13" ry="9" fill="#666"/>

        {/* Database / stack */}
        <g transform="translate(285, 120)">
            <rect x="0" y="0" width="50" height="12" rx="4" fill="#555"/>
            <rect x="0" y="16" width="50" height="12" rx="4" fill="#444"/>
            <rect x="0" y="32" width="50" height="12" rx="4" fill="#3a3a3a"/>
        </g>

        {/* Dots */}
        <circle cx="60" cy="200" r="4" fill="#888" opacity="0.6"/>
        <circle cx="320" cy="175" r="3" fill="#aaa" opacity="0.5"/>
        <circle cx="80" cy="280" r="3" fill="#999" opacity="0.5"/>
    </svg>
);

export default function AdminRegister() {
    const navigate = useNavigate();
    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (password !== confirmPassword) {
            setError('Passwords do not match.');
            return;
        }
        if (password.length < 6) {
            setError('Password must be at least 6 characters.');
            return;
        }

        setLoading(true);
        try {
            await registerAdmin(name, email, password);
            navigate('/');
        } catch (err) {
            if (err.code === 'auth/email-already-in-use') {
                setError('This email is already registered.');
            } else if (err.code === 'auth/weak-password') {
                setError('Password is too weak. Use at least 6 characters.');
            } else {
                setError(err.message || 'Registration failed. Please try again.');
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-page">
            <div className="auth-card">
                {/* ── Left Panel ── */}
                <div className="auth-left">
                    <div className="auth-left-inner">
                        <h1 className="auth-title">Create Account!</h1>
                        <p className="auth-subtitle">Get started with administrative privileges</p>

                        {error && <div className="auth-error">{error}</div>}

                        <form onSubmit={handleSubmit} className="auth-form">
                            <div className="auth-field">
                                <label className="auth-label">Name</label>
                                <input
                                    id="register-name"
                                    type="text"
                                    className="auth-input"
                                    placeholder="Simran Koshta"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    required
                                    autoComplete="name"
                                />
                            </div>

                            <div className="auth-field">
                                <label className="auth-label">Email Address</label>
                                <input
                                    id="register-email"
                                    type="email"
                                    className="auth-input"
                                    placeholder="nits_email@nitc.ac.in"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                    autoComplete="email"
                                />
                            </div>

                            <div className="auth-field">
                                <label className="auth-label">Password</label>
                                <input
                                    id="register-password"
                                    type="password"
                                    className="auth-input"
                                    placeholder="••••••••••"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                    autoComplete="new-password"
                                />
                            </div>

                            <div className="auth-field">
                                <label className="auth-label">Confirm Password</label>
                                <input
                                    id="register-confirm-password"
                                    type="password"
                                    className="auth-input"
                                    placeholder="••••••••••"
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                    required
                                    autoComplete="new-password"
                                />
                            </div>

                            <button
                                id="register-btn"
                                type="submit"
                                className="auth-btn-primary"
                                disabled={loading}
                            >
                                {loading ? 'Creating Account…' : 'Register Account'}
                            </button>
                        </form>

                        <Link to="/login" className="auth-btn-outline" id="goto-login-link">
                            Already have an account? <strong>Login</strong>
                        </Link>
                    </div>
                </div>

                {/* ── Right Panel ── */}
                <div className="auth-right">
                    <AdminIllustration />
                </div>
            </div>
        </div>
    );
}
