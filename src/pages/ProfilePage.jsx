import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { LuUser, LuMail, LuCamera, LuCheck, LuX, LuPenLine, LuChevronLeft, LuLoaderCircle } from 'react-icons/lu';
import Header from '../components/Header';
import { useNavigate } from 'react-router-dom';

const ProfilePage = () => {
    const { userData, updateUserData, currentUser } = useAuth();
    const navigate = useNavigate();
    const [isEditing, setIsEditing] = useState(false);
    const [name, setName] = useState(userData?.name || '');
    const [profilePic, setProfilePic] = useState(userData?.profileImageUrl || '');
    const [loading, setLoading] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [message, setMessage] = useState({ type: '', text: '' });
    const fileInputRef = useRef(null);

    useEffect(() => {
        if (userData) {
            setName(userData.name || '');
            setProfilePic(userData.profileImageUrl || '');
        }
    }, [userData]);

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (!file) return;

        // basic validation
        if (!file.type.startsWith('image/')) {
            setMessage({ type: 'error', text: 'Please select an image file.' });
            return;
        }

        // Limit file size (e.g., 2MB)
        if (file.size > 2 * 1024 * 1024) {
            setMessage({ type: 'error', text: 'Image size should be less than 2MB for encoded storage.' });
            return;
        }

        const reader = new FileReader();
        reader.onloadstart = () => setUploading(true);
        reader.onloadend = () => {
            setProfilePic(reader.result);
            setUploading(false);
            setMessage({ type: 'success', text: 'Image loaded successfully! Click save to apply.' });
            setTimeout(() => setMessage({ type: '', text: '' }), 3000);
        };
        reader.onerror = () => {
            setUploading(false);
            setMessage({ type: 'error', text: 'Failed to read file.' });
        };
        reader.readAsDataURL(file);
    };

    const handleSave = async (e) => {
        e.preventDefault();
        setLoading(true);
        setMessage({ type: '', text: '' });

        const result = await updateUserData({ name, profileImageUrl: profilePic });

        if (result.success) {
            setMessage({ type: 'success', text: 'Profile updated successfully!' });
            setIsEditing(false);
        } else {
            setMessage({ type: 'error', text: 'Failed to update profile. Please try again.' });
        }
        setLoading(false);
        setTimeout(() => setMessage({ type: '', text: '' }), 3500);
    };

    const handleCancel = () => {
        setName(userData?.name || '');
        setProfilePic(userData?.profileImageUrl || '');
        setIsEditing(false);
        setMessage({ type: '', text: '' });
    };

    const triggerFileInput = () => {
        if (isEditing && !uploading) {
            fileInputRef.current?.click();
        }
    };

    return (
        <div className="profile-page-container">
            <Header title="Admin Profile" onBack={() => navigate(-1)} />

            <div className="profile-content">
                <div className="profile-card animate-fade-in">
                    <div className="profile-card-header">
                        <div className="profile-avatar-wrapper">
                            <div
                                className={`profile-avatar-main ${isEditing ? 'clickable-avatar' : ''}`}
                                onClick={triggerFileInput}
                            >
                                {profilePic ? (
                                    <img
                                        src={profilePic}
                                        alt="Admin Profile"
                                        onError={(e) => {
                                            e.target.src = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=100&auto=format&fit=crop";
                                        }}
                                    />
                                ) : (
                                    <div className="profile-no-pic"><LuUser size={48} /></div>
                                )}
                                {isEditing && (
                                    <div className="profile-avatar-overlay">
                                        {uploading ? <LuLoaderCircle className="spinning-icon" size={24} /> : <LuCamera size={24} />}
                                    </div>
                                )}
                            </div>
                            <input
                                type="file"
                                ref={fileInputRef}
                                onChange={handleImageChange}
                                style={{ display: 'none' }}
                                accept="image/*"
                            />
                        </div>

                        {!isEditing ? (
                            <div className="profile-info-basic">
                                <h2 className="profile-name-display">{userData?.name || 'Admin'}</h2>
                                <span className="profile-badge">Administrator</span>
                            </div>
                        ) : (
                            <div className="profile-info-basic">
                                <h2 className="profile-name-display">Editing Profile</h2>
                                <span className="profile-badge editing">Changes Pending</span>
                            </div>
                        )}
                    </div>

                    <div className="profile-card-body">
                        {message.text && (
                            <div className={`profile-message ${message.type}`}>
                                {message.type === 'success' ? <LuCheck /> : <LuX />}
                                {message.text}
                            </div>
                        )}

                        <form onSubmit={handleSave} className="profile-form">
                            <div className="profile-form-group">
                                <label><LuUser /> Full Name</label>
                                <div className="profile-input-wrapper">
                                    <input
                                        type="text"
                                        value={name}
                                        onChange={(e) => setName(e.target.value)}
                                        disabled={!isEditing}
                                        placeholder="Enter your name"
                                        className={isEditing ? 'editable' : ''}
                                    />
                                </div>
                            </div>

                            <div className="profile-form-group">
                                <label><LuMail /> Email Address</label>
                                <div className="profile-input-wrapper readonly">
                                    <input
                                        type="email"
                                        value={userData?.email || ''}
                                        readOnly
                                        className="readonly"
                                    />
                                    <span className="input-tip">Email cannot be changed</span>
                                </div>
                            </div>

                            <div className="profile-actions">
                                {!isEditing ? (
                                    <button
                                        type="button"
                                        className="profile-btn-edit"
                                        onClick={() => setIsEditing(true)}
                                    >
                                        <LuPenLine /> Edit Profile
                                    </button>
                                ) : (
                                    <div className="profile-btns-container">
                                        <button
                                            type="button"
                                            className="profile-btn-cancel"
                                            onClick={handleCancel}
                                            disabled={loading || uploading}
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            className="profile-btn-save"
                                            disabled={loading || uploading}
                                        >
                                            {loading ? 'Saving...' : 'Save Changes'}
                                        </button>
                                    </div>
                                )}
                            </div>
                        </form>
                    </div>
                </div>

            </div>
        </div>
    );
};

export default ProfilePage;
