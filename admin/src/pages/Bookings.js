import React, { useEffect, useState } from 'react';
import api from '../services/api';
import {
    Search,
    Filter,
    Calendar,
    User,
    MapPin,
    Clock,
    CheckCircle2,
    XCircle,
    AlertCircle
} from 'lucide-react';

const Bookings = () => {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchBookings = async () => {
            try {
                const response = await api.get('/admin/bookings');
                setBookings(response.data);
            } catch (err) {
                console.error('Failed to fetch bookings:', err);
            } finally {
                setLoading(false);
            }
        };
        fetchBookings();
    }, []);

    if (loading) return <div style={styles.loading}>Loading Bookings...</div>;

    const getStatusIcon = (status) => {
        switch (status) {
            case 'completed': return <CheckCircle2 size={16} color="#059669" />;
            case 'cancelled': return <XCircle size={16} color="#dc2626" />;
            case 'pending': return <Clock size={16} color="#d97706" />;
            default: return <AlertCircle size={16} color="#2563eb" />;
        }
    }

    return (
        <div style={styles.container}>
            <header style={styles.header}>
                <div>
                    <h1 style={styles.title}>Service Requests</h1>
                    <p style={styles.subtitle}>Monitor and manage all bookings in the system.</p>
                </div>
            </header>

            <div style={styles.filterBar}>
                <div style={styles.searchWrapper}>
                    <Search size={18} style={styles.searchIcon} />
                    <input type="text" placeholder="Search by customer or worker..." style={styles.searchInput} />
                </div>
                <button style={styles.filterBtn}>
                    <Filter size={18} />
                    <span>Filter</span>
                </button>
            </div>

            <div style={styles.tableCard}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Date & ID</th>
                            <th style={styles.th}>Customer</th>
                            <th style={styles.th}>Service</th>
                            <th style={styles.th}>Location</th>
                            <th style={styles.th}>Amount</th>
                            <th style={styles.th}>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        {bookings.map((booking) => (
                            <tr key={booking._id} style={styles.tr}>
                                <td style={styles.td}>
                                    <div style={styles.idCell}>
                                        <span style={styles.dateText}>{new Date(booking.date).toLocaleDateString()}</span>
                                        <span style={styles.idText}>#{booking._id.slice(-6).toUpperCase()}</span>
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <div style={styles.userCell}>
                                        <User size={16} style={styles.userIcon} />
                                        <span>{booking.user?.name || 'User'}</span>
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <div style={styles.categoryCell}>{booking.category}</div>
                                </td>
                                <td style={styles.td}>
                                    <div style={styles.locationCell}>
                                        <MapPin size={14} style={{ marginRight: 4 }} />
                                        <span style={styles.addressText}>{booking.address || 'Location N/A'}</span>
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <span style={styles.amountText}>₹{booking.amount || '0'}</span>
                                </td>
                                <td style={styles.td}>
                                    <div style={{
                                        ...styles.statusBadge,
                                        ...getStatusStyle(booking.status)
                                    }}>
                                        {getStatusIcon(booking.status)}
                                        <span style={{ marginLeft: 6 }}>{booking.status}</span>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const getStatusStyle = (status) => {
    switch (status) {
        case 'completed': return { background: '#ecfdf5', color: '#059669' };
        case 'pending': return { background: '#fffbeb', color: '#d97706' };
        case 'confirmed': return { background: '#eff6ff', color: '#2563eb' };
        case 'cancelled': return { background: '#fef2f2', color: '#dc2626' };
        default: return { background: '#f8fafc', color: '#64748b' };
    }
}

const styles = {
    container: {
        display: 'flex',
        flexDirection: 'column',
        gap: '2rem',
    },
    header: {
        marginBottom: '0.5rem',
    },
    title: {
        fontSize: '1.75rem',
        fontWeight: '800',
        color: '#1e293b',
        margin: 0,
    },
    subtitle: {
        color: '#64748b',
        marginTop: '0.4rem',
    },
    filterBar: {
        display: 'flex',
        gap: '1rem',
    },
    searchWrapper: {
        position: 'relative',
        flex: 1,
        maxWidth: '400px',
    },
    searchIcon: {
        position: 'absolute',
        left: '1rem',
        top: '50%',
        transform: 'translateY(-50%)',
        color: '#94a3b8',
    },
    searchInput: {
        width: '100%',
        padding: '0.75rem 1rem 0.75rem 3rem',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        background: 'white',
        outline: 'none',
    },
    filterBtn: {
        padding: '0.75rem 1.25rem',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        background: 'white',
        color: '#1e293b',
        fontWeight: '600',
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        cursor: 'pointer',
    },
    tableCard: {
        background: 'white',
        borderRadius: '20px',
        border: '1px solid #e2e8f0',
        overflow: 'hidden',
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
    },
    th: {
        textAlign: 'left',
        padding: '1rem 1.5rem',
        fontSize: '0.8rem',
        fontWeight: '600',
        color: '#64748b',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        background: '#f8fafc',
        borderBottom: '1px solid #f1f5f9',
    },
    tr: {
        borderBottom: '1px solid #f1f5f9',
    },
    td: {
        padding: '1.25rem 1.5rem',
        fontSize: '0.9rem',
        color: '#1e293b',
        verticalAlign: 'middle',
    },
    idCell: {
        display: 'flex',
        flexDirection: 'column',
    },
    dateText: {
        fontWeight: '600',
        color: '#1e293b',
    },
    idText: {
        fontSize: '0.75rem',
        color: '#94a3b8',
        fontFamily: 'monospace',
    },
    userCell: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        fontWeight: '500',
    },
    userIcon: {
        color: '#64748b',
    },
    categoryCell: {
        background: '#f1f5f9',
        padding: '0.2rem 0.6rem',
        borderRadius: '6px',
        fontSize: '0.8rem',
        fontWeight: '600',
        display: 'inline-block',
    },
    locationCell: {
        display: 'flex',
        alignItems: 'flex-start',
        maxWidth: '200px',
        color: '#64748b',
    },
    addressText: {
        fontSize: '0.85rem',
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap',
    },
    amountText: {
        fontWeight: '700',
        color: '#1e293b',
    },
    statusBadge: {
        padding: '0.4rem 0.8rem',
        borderRadius: '100px',
        fontSize: '0.75rem',
        fontWeight: '700',
        textTransform: 'uppercase',
        display: 'flex',
        alignItems: 'center',
        width: 'fit-content',
    },
    loading: {
        display: 'flex',
        height: '100%',
        alignItems: 'center',
        justifyContent: 'center',
    }
};

export default Bookings;
