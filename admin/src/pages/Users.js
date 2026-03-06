import React, { useEffect, useState } from 'react';
import api from '../services/api';
import {
    User,
    Shield,
    Mail,
    Calendar,
    Search,
    MoreVertical,
    CheckCircle
} from 'lucide-react';

const Users = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchUsers = async () => {
            try {
                const response = await api.get('/admin/users');
                setUsers(response.data);
            } catch (err) {
                console.error('Failed to fetch users:', err);
            } finally {
                setLoading(false);
            }
        };
        fetchUsers();
    }, []);

    if (loading) return <div style={styles.loading}>Loading Users...</div>;

    const getRoleBadge = (role) => {
        switch (role) {
            case 'admin': return { background: '#fef3c7', color: '#92400e', icon: <Shield size={12} /> };
            case 'worker': return { background: '#dcfce7', color: '#166534', icon: <CheckCircle size={12} /> };
            default: return { background: '#f1f5f9', color: '#475569', icon: <User size={12} /> };
        }
    }

    return (
        <div style={styles.container}>
            <header style={styles.header}>
                <div>
                    <h1 style={styles.title}>User Management</h1>
                    <p style={styles.subtitle}>Review and manage application users and workers.</p>
                </div>
            </header>

            <div style={styles.filterBar}>
                <div style={styles.searchWrapper}>
                    <Search size={18} style={styles.searchIcon} />
                    <input type="text" placeholder="Search by name or email..." style={styles.searchInput} />
                </div>
            </div>

            <div style={styles.tableCard}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>User Details</th>
                            <th style={styles.th}>Role</th>
                            <th style={styles.th}>Joined Date</th>
                            <th style={styles.th}>Status</th>
                            <th style={styles.th}></th>
                        </tr>
                    </thead>
                    <tbody>
                        {users.map((user) => (
                            <tr key={user._id} style={styles.tr}>
                                <td style={styles.td}>
                                    <div style={styles.userCell}>
                                        <div style={styles.avatar}>
                                            {user.name.charAt(0)}
                                        </div>
                                        <div style={styles.userInfo}>
                                            <span style={styles.userName}>{user.name}</span>
                                            <span style={styles.userEmail}><Mail size={12} style={{ marginRight: 4 }} /> {user.email}</span>
                                        </div>
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <div style={{
                                        ...styles.roleBadge,
                                        ...getRoleBadge(user.role)
                                    }}>
                                        {getRoleBadge(user.role).icon}
                                        <span style={{ marginLeft: 6 }}>{user.role}</span>
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <div style={styles.dateCell}>
                                        <Calendar size={14} style={{ marginRight: 6 }} />
                                        {new Date(user.createdAt).toLocaleDateString()}
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <span style={styles.activeStatus}>Active</span>
                                </td>
                                <td style={styles.td}>
                                    <button style={styles.actionBtn}>
                                        <MoreVertical size={18} />
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

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
        padding: '1rem 1.5rem',
        fontSize: '0.9rem',
        color: '#1e293b',
        verticalAlign: 'middle',
    },
    userCell: {
        display: 'flex',
        alignItems: 'center',
        gap: '1rem',
    },
    avatar: {
        width: '40px',
        height: '40px',
        background: '#eff6ff',
        color: '#3b82f6',
        borderRadius: '12px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: '700',
        fontSize: '1.25rem',
    },
    userInfo: {
        display: 'flex',
        flexDirection: 'column',
    },
    userName: {
        fontWeight: '700',
        color: '#1e293b',
    },
    userEmail: {
        fontSize: '0.8rem',
        color: '#64748b',
        display: 'flex',
        alignItems: 'center',
    },
    roleBadge: {
        padding: '0.35rem 0.75rem',
        borderRadius: '100px',
        fontSize: '0.7rem',
        fontWeight: '700',
        textTransform: 'uppercase',
        display: 'flex',
        alignItems: 'center',
        width: 'fit-content',
    },
    dateCell: {
        display: 'flex',
        alignItems: 'center',
        color: '#64748b',
    },
    activeStatus: {
        color: '#059669',
        fontWeight: '600',
        fontSize: '0.85rem',
    },
    actionBtn: {
        background: 'transparent',
        border: 'none',
        color: '#94a3b8',
        cursor: 'pointer',
    },
    loading: {
        display: 'flex',
        height: '100%',
        alignItems: 'center',
        justifyContent: 'center',
    }
};

export default Users;
