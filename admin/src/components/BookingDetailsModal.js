import React from 'react';
import { X, Calendar, MapPin, User, Clock, IndianRupee, FileText } from 'lucide-react';

const BookingDetailsModal = ({ booking, onClose }) => {
    if (!booking) return null;

    const getStatusStyle = (status) => {
        switch (status) {
            case 'completed': return { background: '#ecfdf5', color: '#059669' };
            case 'pending': return { background: '#fffbeb', color: '#d97706' };
            case 'confirmed': return { background: '#eff6ff', color: '#2563eb' };
            case 'cancelled': return { background: '#fef2f2', color: '#dc2626' };
            default: return { background: '#f8fafc', color: '#64748b' };
        }
    };

    return (
        <div style={styles.overlay}>
            <div style={styles.modal}>
                <div style={styles.header}>
                    <h2 style={styles.title}>Booking Details</h2>
                    <button style={styles.closeBtn} onClick={onClose}><X size={20} /></button>
                </div>

                <div style={styles.content}>
                    <div style={styles.section}>
                        <div style={styles.row}>
                            <div style={styles.item}>
                                <span style={styles.label}>ID</span>
                                <span style={styles.value}>#{booking._id}</span>
                            </div>
                            <div style={styles.item}>
                                <span style={styles.label}>Status</span>
                                <span style={{ ...styles.statusBadge, ...getStatusStyle(booking.status) }}>
                                    {booking.status}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div style={styles.section}>
                        <h3 style={styles.sectionTitle}>Service Information</h3>
                        <div style={styles.row}>
                            <div style={styles.item}>
                                <span style={styles.label}><BriefcaseIcon size={14}/> Category</span>
                                <span style={styles.value}>{booking.category}</span>
                            </div>
                            <div style={styles.item}>
                                <span style={styles.label}><Calendar size={14}/> Date</span>
                                <span style={styles.value}>{new Date(booking.date).toLocaleString()}</span>
                            </div>
                        </div>
                        <div style={styles.row}>
                            <div style={styles.item}>
                                <span style={styles.label}><Clock size={14}/> Hours</span>
                                <span style={styles.value}>{booking.numberOfHours || 'N/A'}</span>
                            </div>
                            <div style={styles.item}>
                                <span style={styles.label}><IndianRupee size={14}/> Amount</span>
                                <span style={styles.value}>
                                    {booking.minAmount && booking.maxAmount
                                        ? `₹${booking.minAmount} - ₹${booking.maxAmount}`
                                        : `₹${booking.amount || '0'}`}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div style={styles.section}>
                        <h3 style={styles.sectionTitle}>Customer</h3>
                        <div style={styles.row}>
                            <div style={styles.item}>
                                <span style={styles.label}><User size={14}/> Name</span>
                                <span style={styles.value}>{booking.user?.name || 'Unknown User'}</span>
                            </div>
                            <div style={styles.item}>
                                <span style={styles.label}>Contact</span>
                                <span style={styles.value}>{booking.user?.phoneNumber || booking.user?.email || 'N/A'}</span>
                            </div>
                        </div>
                    </div>

                    {booking.labourer && (
                        <div style={styles.section}>
                            <h3 style={styles.sectionTitle}>Assigned Worker</h3>
                            <div style={styles.row}>
                                <div style={styles.item}>
                                    <span style={styles.label}><User size={14}/> Name</span>
                                    <span style={styles.value}>{booking.labourer?.name || 'Unknown'}</span>
                                </div>
                                <div style={styles.item}>
                                    <span style={styles.label}>Contact</span>
                                    <span style={styles.value}>{booking.labourer?.phoneNumber || 'N/A'}</span>
                                </div>
                            </div>
                        </div>
                    )}

                    <div style={styles.section}>
                        <h3 style={styles.sectionTitle}>Location & Notes</h3>
                        <div style={styles.fullItem}>
                            <span style={styles.label}><MapPin size={14}/> Address</span>
                            <span style={styles.value}>{booking.address || 'N/A'}</span>
                        </div>
                        <div style={styles.fullItem}>
                            <span style={styles.label}><FileText size={14}/> Notes</span>
                            <div style={styles.notesBox}>
                                {booking.notes || 'No notes provided by the customer.'}
                            </div>
                        </div>
                    </div>
                </div>
                
                <div style={styles.footer}>
                    <button style={styles.btnPrimary} onClick={onClose}>Close</button>
                </div>
            </div>
        </div>
    );
};

const BriefcaseIcon = ({ size }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
        <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
    </svg>
);

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
        maxWidth: '600px',
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
    fullItem: {
        display: 'flex',
        flexDirection: 'column',
        gap: '0.25rem',
        marginTop: '0.5rem',
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
    statusBadge: {
        padding: '0.25rem 0.75rem',
        borderRadius: '100px',
        fontSize: '0.75rem',
        fontWeight: '700',
        textTransform: 'uppercase',
        width: 'fit-content',
    },
    notesBox: {
        background: '#f8fafc',
        padding: '1rem',
        borderRadius: '12px',
        fontSize: '0.9rem',
        color: '#475569',
        lineHeight: '1.5',
        border: '1px solid #e2e8f0',
        marginTop: '0.25rem',
    },
    footer: {
        padding: '1.25rem 1.5rem',
        borderTop: '1px solid #f1f5f9',
        display: 'flex',
        justifyContent: 'flex-end',
        background: '#f8fafc',
    },
    btnPrimary: {
        background: '#1e293b',
        color: 'white',
        border: 'none',
        padding: '0.75rem 1.5rem',
        borderRadius: '12px',
        fontWeight: '600',
        cursor: 'pointer',
    }
};

export default BookingDetailsModal;
