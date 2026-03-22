// src/pages/Auth/AdminLogin.jsx
import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { loginAdmin, sendAdminPasswordReset } from '../../services/authService';
import '../../styles/auth.css';

const MapIllustration = () => (
    <svg viewBox="0 0 380 320" fill="none" xmlns="http://www.w3.org/2000/svg" className="auth-illustration">
        {/* Map base */}
        <ellipse cx="190" cy="230" rx="155" ry="65" fill="#3a3a3a" opacity="0.6"/>
        <path d="M70 180 Q110 140 160 160 Q200 175 240 155 Q280 135 310 165 L320 240 Q280 260 240 245 Q200 230 160 248 Q120 265 70 245 Z" fill="#4a4a4a"/>
        <path d="M85 185 Q120 150 165 168 Q205 182 245 162 Q275 148 305 170" stroke="#666" strokeWidth="2" strokeDasharray="8 4" fill="none"/>

        {/* Location pins */}
        <g transform="translate(185, 90)">
            <path d="M0 -42 C-18 -42 -32 -28 -32 -10 C-32 15 0 45 0 45 C0 45 32 15 32 -10 C32 -28 18 -42 0 -42Z" fill="#e0e0e0"/>
            <circle cx="0" cy="-10" r="13" fill="#2a2a2a"/>
        </g>
        <g transform="translate(118, 155)">
            <path d="M0 -28 C-12 -28 -21 -19 -21 -8 C-21 8 0 28 0 28 C0 28 21 8 21 -8 C21 -19 12 -28 0 -28Z" fill="#b0b0b0"/>
            <circle cx="0" cy="-8" r="8" fill="#2a2a2a"/>
        </g>
        <g transform="translate(260, 135)">
            <path d="M0 -22 C-9 -22 -16 -15 -16 -6 C-16 6 0 22 0 22 C0 22 16 6 16 -6 C16 -15 9 -22 0 -22Z" fill="#888"/>
            <circle cx="0" cy="-6" r="6" fill="#2a2a2a"/>
        </g>

        {/* Person with magnifying glass */}
        <g transform="translate(130, 115)">
            {/* Body */}
            <ellipse cx="0" cy="35" rx="20" ry="25" fill="#888"/>
            {/* Head */}
            <circle cx="0" cy="-5" r="18" fill="#aaa"/>
            {/* Glasses */}
            <circle cx="-6" cy="-5" r="6" stroke="#555" strokeWidth="2" fill="none"/>
            <circle cx="6" cy="-5" r="6" stroke="#555" strokeWidth="2" fill="none"/>
            <line x1="-12" y1="-5" x2="-15" y2="-5" stroke="#555" strokeWidth="1.5"/>
            <line x1="12" y1="-5" x2="15" y2="-5" stroke="#555" strokeWidth="1.5"/>
            <line x1="0" y1="-5" x2="0" y2="-5" stroke="#555" strokeWidth="1.5"/>
            {/* Arm with magnifying glass */}
            <line x1="20" y1="20" x2="52" y2="-10" stroke="#777" strokeWidth="4" strokeLinecap="round"/>
            <circle cx="56" cy="-14" r="18" stroke="#bbb" strokeWidth="4" fill="none"/>
            <line x1="69" y1="-27" x2="80" y2="-40" stroke="#bbb" strokeWidth="5" strokeLinecap="round"/>
            {/* Legs */}
            <line x1="-8" y1="60" x2="-15" y2="90" stroke="#777" strokeWidth="6" strokeLinecap="round"/>
            <line x1="8" y1="60" x2="18" y2="85" stroke="#777" strokeWidth="6" strokeLinecap="round"/>
            {/* Shoes */}
            <ellipse cx="-16" cy="93" rx="10" ry="5" fill="#555"/>
            <ellipse cx="20" cy="88" rx="10" ry="5" fill="#555"/>
        </g>

        {/* Sparkles */}
        <circle cx="100" cy="110" r="3" fill="#aaa" opacity="0.7"/>
        <circle cx="280" cy="100" r="4" fill="#ccc" opacity="0.6"/>
        <circle cx="310" cy="200" r="3" fill="#bbb" opacity="0.5"/>
        <circle cx="75" cy="220" r="2" fill="#999" opacity="0.6"/>
    </svg>
);

export default function AdminLogin() {
    const navigate = useNavigate();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [rememberMe, setRememberMe] = useState(false);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [resetMsg, setResetMsg] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setResetMsg('');
        setLoading(true);
        try {
            await loginAdmin(email, password);
            navigate('/');
        } catch (err) {
            setError(err.message || 'Login failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const handleForgotPassword = async () => {
        if (!email) {
            setError('Please enter your email address first.');
            return;
        }
        try {
            await sendAdminPasswordReset(email);
            setResetMsg('Password reset email sent! Check your inbox.');
            setError('');
        } catch (err) {
            setError('Failed to send reset email. Check the address and try again.');
        }
    };

    return (
        <div className="auth-page">
            <div className="auth-card">
                {/* ── Left Panel ── */}
                <div className="auth-left">
                    <div className="auth-left-inner">
                        <h1 className="auth-title">Welcome Back!</h1>
                        <p className="auth-subtitle">Please enter your credentials to access the console.</p>

                        {error && <div className="auth-error">{error}</div>}
                        {resetMsg && <div className="auth-success">{resetMsg}</div>}

                        <form onSubmit={handleSubmit} className="auth-form">
                            <div className="auth-field">
                                <label className="auth-label">Email Address</label>
                                <input
                                    id="login-email"
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
                                    id="login-password"
                                    type="password"
                                    className="auth-input"
                                    placeholder="••••••••••"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                    autoComplete="current-password"
                                />
                            </div>

                            <div className="auth-row">
                                <label className="auth-toggle-label">
                                    <div
                                        className={`auth-toggle ${rememberMe ? 'auth-toggle--on' : ''}`}
                                        onClick={() => setRememberMe(!rememberMe)}
                                        role="switch"
                                        aria-checked={rememberMe}
                                        id="remember-me-toggle"
                                    >
                                        <div className="auth-toggle-knob" />
                                    </div>
                                    <span>Remember me</span>
                                </label>
                                <button
                                    type="button"
                                    className="auth-link-btn"
                                    onClick={handleForgotPassword}
                                    id="forgot-password-btn"
                                >
                                    Forgot Password?
                                </button>
                            </div>

                            <button
                                id="sign-in-btn"
                                type="submit"
                                className="auth-btn-primary"
                                disabled={loading}
                            >
                                {loading ? 'Signing in…' : 'Sign In'}
                            </button>
                        </form>

                        <p className="auth-footer-text">
                            Not a member?{' '}
                            <Link to="/register" className="auth-link-strong" id="goto-register-link">
                                Register now
                            </Link>
                        </p>
                    </div>
                </div>

                {/* ── Right Panel ── */}
                <div className="auth-right">
                    <MapIllustration />
                </div>
            </div>
        </div>
    );
}
