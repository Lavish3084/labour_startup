import React from 'react';
import { X, User, Mail, Phone, Calendar, Shield, MapPin, CheckCircle, Briefcase } from 'lucide-react';

const UserDetailsModal = ({ user, onClose }) => {
    if (!user) return null;

    const isWorker = user.role === 'worker';
    const isAdmin = user.role === 'admin';

    const getRoleBadge = (role) => {
        switch (role) {
            case 'admin': return { background: '#fef3c7', color: '#92400e', icon: <Shield size={14} /> };
            case 'worker': return { background: '#dcfce7', color: '#166534', icon: <Briefcase size={14} /> };
            default: return { background: '#f1f5f9', color: '#475569', icon: <User size={14} /> };
        }
    };

    const roleBadge = getRoleBadge(user.role);

    return (
        <div style={styles.overlay}>
            <div style={styles.modal}>
                <div style={styles.header}>
                    <h2 style={styles.title}>User Details</h2>
                    <button style={styles.closeBtn} onClick={onClose}><X size={20} /></button>
                </div>

                <div style={styles.content}>
                    {/* Profile Header */}
                    <div style={styles.profileHeader}>
                        <div style={styles.avatarLarge}>
                            {user.name?.charAt(0).toUpperCase()}
                        </div>
                        <div style={styles.profileInfo}>
                            <h3 style={styles.profileName}>{user.name}</h3>
                            <div style={{ ...styles.roleBadge, background: roleBadge.background, color: roleBadge.color }}>
                                {roleBadge.icon}
                                <span style={{ marginLeft: 6 }}>{user.role}</span>
                            </div>
                        </div>
                    </div>

                    <div style={styles.section}>
                        <h3 style={styles.sectionTitle}>Contact Information</h3>
                        <div style={styles.row}>
                            <div style={styles.item}>
                                <span style={styles.label}><Mail size={14}/> Email</span>
                                <span style={styles.value}>{user.email || 'N/A'}</span>
                            </div>
                            <div style={styles.item}>
                                <span style={styles.label}><Phone size={14}/> Phone</span>
                                <span style={styles.value}>{user.phoneNumber || 'N/A'}</span>
                            </div>
                        </div>
                        <div style={styles.row}>
                            <div style={styles.item}>
                                <span style={styles.label}><Calendar size={14}/> Joined Date</span>
                                <span style={styles.value}>{new Date(user.createdAt).toLocaleString()}</span>
                            </div>
                            <div style={styles.item}>
                                <span style={styles.label}><CheckCircle size={14}/> Status</span>
                                <span style={styles.activeStatus}>Active</span>
                            </div>
                        </div>
                    </div>

                    {isWorker && (
                        <div style={styles.section}>
                            <h3 style={styles.sectionTitle}>Worker Profile</h3>
                            <div style={styles.row}>
                                <div style={styles.item}>
                                    <span style={styles.label}>Experience</span>
                                    <span style={styles.value}>{user.experienceYears ? `${user.experienceYears} years` : 'N/A'}</span>
                                </div>
                                <div style={styles.item}>
                                    <span style={styles.label}>Location / Base</span>
                                    <span style={styles.value}>
                                        {user.latitude && user.longitude 
                                            ? `${parseFloat(user.latitude).toFixed(4)}, ${parseFloat(user.longitude).toFixed(4)}` 
                                            : 'N/A'}
                                    </span>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
                
                <div style={styles.footer}>
                    <button style={styles.btnSecondary} onClick={onClose}>Close</button>
                    {!isAdmin && (
                        <button style={styles.btnDanger}>Suspend User</button>
                    )}
                </div>
            </div>
        </div>
    );
};

const styles = {
    overlay: {
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.4)',
        backdropFilter: 'blur(4px)',
        zIndex: 1000,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '1rem',
    },
    modal: {
        background: 'white',
        borderRadius: '24px',
        width: '100%',
        maxWidth: '500px',
        maxHeight: '90vh',
        display: 'flex',
        flexDirection: 'column',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
        overflow: 'hidden',
    },
    header: {
        padding: '1.5rem',
        borderBottom: '1px solid #f1f5f9',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    title: {
        margin: 0,
        fontSize: '1.25rem',
        fontWeight: '700',
        color: '#1e293b',
    },
    closeBtn: {
        background: '#f1f5f9',
        border: 'none',
        borderRadius: '50%',
        width: '36px',
        height: '36px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        color: '#64748b',
        transition: 'background 0.2s',
    },
    content: {
        padding: '1.5rem',
        overflowY: 'auto',
        display: 'flex',
        flexDirection: 'column',
        gap: '1.5rem',
    },
    profileHeader: {
        display: 'flex',
        alignItems: 'center',
        gap: '1.25rem',
        paddingBottom: '1.5rem',
        borderBottom: '1px solid #f1f5f9',
    },
    avatarLarge: {
        width: '64px',
        height: '64px',
        background: '#eff6ff',
        color: '#3b82f6',
        borderRadius: '20px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: '800',
        fontSize: '2rem',
    },
    profileInfo: {
        display: 'flex',
        flexDirection: 'column',
        gap: '0.5rem',
    },
    profileName: {
        margin: 0,
        fontSize: '1.5rem',
        fontWeight: '800',
        color: '#1e293b',
    },
    roleBadge: {
        padding: '0.35rem 0.75rem',
        borderRadius: '100px',
        fontSize: '0.75rem',
        fontWeight: '700',
        textTransform: 'uppercase',
        display: 'flex',
        alignItems: 'center',
        width: 'fit-content',
    },
    section: {
        display: 'flex',
        flexDirection: 'column',
        gap: '1rem',
    },
    sectionTitle: {
        margin: 0,
        fontSize: '1rem',
        fontWeight: '600',
        color: '#475569',
        borderBottom: '1px solid #f1f5f9',
        paddingBottom: '0.5rem',
    },
    row: {
        display: 'flex',
        gap: '1.5rem',
    },
    item: {
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        gap: '0.25rem',
    },
    label: {
        fontSize: '0.75rem',
        color: '#64748b',
        fontWeight: '600',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        display: 'flex',
        alignItems: 'center',
        gap: '0.35rem',
    },
    value: {
        fontSize: '0.95rem',
        color: '#1e293b',
        fontWeight: '500',
        lineHeight: '1.4',
    },
    activeStatus: {
        color: '#059669',
        fontWeight: '600',
        fontSize: '0.95rem',
    },
    footer: {
        padding: '1.25rem 1.5rem',
        borderTop: '1px solid #f1f5f9',
        display: 'flex',
        justifyContent: 'flex-end',
        gap: '1rem',
        background: '#f8fafc',
    },
    btnSecondary: {
        background: 'white',
        color: '#475569',
        border: '1px solid #e2e8f0',
        padding: '0.75rem 1.5rem',
        borderRadius: '12px',
        fontWeight: '600',
        cursor: 'pointer',
    },
    btnDanger: {
        background: '#fef2f2',
        color: '#dc2626',
        border: '1px solid #fecaca',
        padding: '0.75rem 1.5rem',
        borderRadius: '12px',
        fontWeight: '600',
        cursor: 'pointer',
    }
};

export default UserDetailsModal;
