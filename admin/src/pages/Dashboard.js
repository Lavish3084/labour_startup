import React, { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import {
    Users,
    Briefcase,
    CheckCircle,
    TrendingUp,
    Clock,
    User,
    Calendar,
    IndianRupee
} from 'lucide-react';

const Dashboard = () => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const result = await adminService.getStats();
                setData(result);
            } catch (err) {
                console.error('Failed to fetch stats:', err);
            } finally {
                setLoading(false);
            }
        };
        fetchStats();
    }, []);

    if (loading) return <div style={styles.loading}>Loading Dashboard...</div>;

    const stats = [
        { label: 'Total Users', value: data?.stats?.totalUsers || 0, icon: <Users />, color: '#3b82f6' },
        { label: 'Waiters/Workers', value: data?.stats?.totalWorkers || 0, icon: <Briefcase />, color: '#10b981' },
        { label: 'Active Users (30d)', value: data?.stats?.activeUsers || 0, icon: <TrendingUp />, color: '#6366f1' },
        { label: 'Total Bookings', value: data?.stats?.totalBookings || 0, icon: <Calendar />, color: '#f59e0b' },
        { label: 'Completed', value: data?.stats?.completedBookings || 0, icon: <CheckCircle />, color: '#8b5cf6' },
        { label: 'Total Revenue', value: `₹${data?.stats?.totalRevenue || 0}`, icon: <IndianRupee />, color: '#ec4899', fullWidth: true },
    ];

    return (
        <div style={styles.container}>
            <header style={styles.header}>
                <h1 style={styles.title}>Overview</h1>
                <p style={styles.subtitle}>Welcome back, here's what's happening today.</p>
            </header>

            {/* Stats Grid */}
            <div style={styles.statsGrid}>
                {stats.map((stat, index) => (
                    <div key={index} style={{
                        ...styles.statCard,
                        gridColumn: stat.fullWidth ? 'span 2' : 'span 1'
                    }}>
                        <div style={{ ...styles.iconContainer, background: `${stat.color}15`, color: stat.color }}>
                            {stat.icon}
                        </div>
                        <div style={styles.statInfo}>
                            <span style={styles.statLabel}>{stat.label}</span>
                            <span style={styles.statValue}>{stat.value}</span>
                        </div>
                    </div>
                ))}
            </div>

            <div style={styles.bottomSection}>
                {/* Recent Bookings */}
                <div style={styles.sectionCard}>
                    <div style={styles.sectionHeader}>
                        <h2 style={styles.sectionTitle}>Recent Bookings</h2>
                        <button style={styles.viewAllBtn}>View All</button>
                    </div>
                    <div style={styles.tableContainer}>
                        <table style={styles.table}>
                            <thead>
                                <tr>
                                    <th style={styles.th}>Customer</th>
                                    <th style={styles.th}>Category</th>
                                    <th style={styles.th}>Date</th>
                                    <th style={styles.th}>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                {data?.recentBookings?.map((booking) => (
                                    <tr key={booking._id} style={styles.tr}>
                                        <td style={styles.td}>
                                            <div style={styles.userCell}>
                                                <div style={styles.avatar}><User size={14} /></div>
                                                {booking.user?.name || 'Unknown'}
                                            </div>
                                        </td>
                                        <td style={styles.td}>{booking.category}</td>
                                        <td style={styles.td}>
                                            <div style={styles.dateCell}>
                                                <Clock size={14} style={{ marginRight: 6 }} />
                                                {new Date(booking.date).toLocaleDateString()}
                                            </div>
                                        </td>
                                        <td style={styles.td}>
                                            <span style={{
                                                ...styles.statusBadge,
                                                ...getStatusStyle(booking.status)
                                            }}>
                                                {booking.status}
                                            </span>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
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
    statsGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: '1.5rem',
    },
    statCard: {
        background: 'white',
        padding: '1.5rem',
        borderRadius: '20px',
        border: '1px solid #e2e8f0',
        display: 'flex',
        alignItems: 'center',
        gap: '1.25rem',
        transition: 'transform 0.2s ease',
    },
    iconContainer: {
        width: '48px',
        height: '48px',
        borderRadius: '14px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
    },
    statInfo: {
        display: 'flex',
        flexDirection: 'column',
    },
    statLabel: {
        fontSize: '0.875rem',
        color: '#64748b',
        fontWeight: '500',
    },
    statValue: {
        fontSize: '1.25rem',
        fontWeight: '700',
        color: '#1e293b',
    },
    bottomSection: {
        display: 'grid',
        gridTemplateColumns: '1fr',
        gap: '1.5rem',
    },
    sectionCard: {
        background: 'white',
        borderRadius: '20px',
        border: '1px solid #e2e8f0',
        overflow: 'hidden',
    },
    sectionHeader: {
        padding: '1.5rem',
        borderBottom: '1px solid #f1f5f9',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    sectionTitle: {
        fontSize: '1.125rem',
        fontWeight: '700',
        color: '#1e293b',
        margin: 0,
    },
    viewAllBtn: {
        background: 'transparent',
        border: 'none',
        color: '#3b82f6',
        fontWeight: '600',
        fontSize: '0.875rem',
        cursor: 'pointer',
    },
    tableContainer: {
        overflowX: 'auto',
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
    },
    tr: {
        borderBottom: '1px solid #f1f5f9',
    },
    td: {
        padding: '1rem 1.5rem',
        fontSize: '0.9rem',
        color: '#1e293b',
    },
    userCell: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.75rem',
    },
    avatar: {
        width: '28px',
        height: '28px',
        background: '#f1f5f9',
        borderRadius: '50%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#64748b',
    },
    dateCell: {
        display: 'flex',
        alignItems: 'center',
        color: '#64748b',
    },
    statusBadge: {
        padding: '0.25rem 0.75rem',
        borderRadius: '100px',
        fontSize: '0.75rem',
        fontWeight: '600',
        textTransform: 'capitalize',
    },
    loading: {
        display: 'flex',
        height: '100%',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#64748b',
    }
};

export default Dashboard;
