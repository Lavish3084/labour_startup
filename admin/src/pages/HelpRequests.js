import React, { useEffect, useState } from 'react';
import api from '../services/api';
import {
    CheckCircle,
    Mail,
    Phone,
    Calendar,
    Search,
    Clock,
    AlertCircle,
    CheckSquare,
    Eye,
    X,
    Filter
} from 'lucide-react';

const HelpRequests = () => {
    const [requests, setRequests] = useState([]);
    const [filteredRequests, setFilteredRequests] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [roleFilter, setRoleFilter] = useState('all');
    const [statusFilter, setStatusFilter] = useState('all');
    const [selectedRequest, setSelectedRequest] = useState(null);

    const fetchRequests = async () => {
        setLoading(true);
        try {
            const response = await api.get('/admin/help-requests');
            setRequests(response.data);
            setFilteredRequests(response.data);
        } catch (err) {
            console.error('Failed to fetch help requests:', err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchRequests();
    }, []);

    // Filter requests
    useEffect(() => {
        let result = requests;

        // Apply search query
        if (searchQuery) {
            const query = searchQuery.toLowerCase();
            result = result.filter(
                (req) =>
                    req.name.toLowerCase().includes(query) ||
                    (req.email && req.email.toLowerCase().includes(query)) ||
                    (req.subject && req.subject.toLowerCase().includes(query)) ||
                    (req.message && req.message.toLowerCase().includes(query))
            );
        }

        // Apply role filter
        if (roleFilter !== 'all') {
            result = result.filter((req) => req.role === roleFilter);
        }

        // Apply status filter
        if (statusFilter !== 'all') {
            result = result.filter((req) => req.status === statusFilter);
        }

        setFilteredRequests(result);
    }, [searchQuery, roleFilter, statusFilter, requests]);

    const handleUpdateStatus = async (id, newStatus) => {
        try {
            await api.put(`/admin/help-requests/${id}`, { status: newStatus });
            // Update state locally
            setRequests((prev) =>
                prev.map((req) => (req._id === id ? { ...req, status: newStatus } : req))
            );
            if (selectedRequest && selectedRequest._id === id) {
                setSelectedRequest((prev) => ({ ...prev, status: newStatus }));
            }
        } catch (err) {
            console.error('Failed to update request status:', err);
        }
    };

    const getStatusBadge = (status) => {
        switch (status) {
            case 'resolved':
                return { background: '#dcfce7', color: '#166534', label: 'Resolved', icon: <CheckSquare size={12} /> };
            case 'in-progress':
                return { background: '#e0f2fe', color: '#0369a1', label: 'In Progress', icon: <Clock size={12} /> };
            default:
                return { background: '#fef3c7', color: '#92400e', label: 'Pending', icon: <AlertCircle size={12} /> };
        }
    };

    const getRoleBadge = (role) => {
        switch (role) {
            case 'worker':
                return { background: '#f0fdf4', color: '#15803d', border: '1px solid #bbf7d0', label: 'Worker' };
            default:
                return { background: '#eff6ff', color: '#1d4ed8', border: '1px solid #bfdbfe', label: 'User' };
        }
    };

    if (loading) return <div style={styles.loading}>Loading Help Requests...</div>;

    return (
        <div style={styles.container}>
            <header style={styles.header}>
                <div>
                    <h1 style={styles.title}>Help & Support Requests</h1>
                    <p style={styles.subtitle}>Review, manage, and resolve help tickets from users and workers.</p>
                </div>
            </header>

            <div style={styles.filterBar}>
                <div style={styles.searchWrapper}>
                    <Search size={18} style={styles.searchIcon} />
                    <input
                        type="text"
                        placeholder="Search by name, email, subject..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        style={styles.searchInput}
                    />
                </div>

                <div style={styles.filterGroup}>
                    <div style={styles.selectWrapper}>
                        <Filter size={14} style={styles.selectIcon} />
                        <select
                            value={roleFilter}
                            onChange={(e) => setRoleFilter(e.target.value)}
                            style={styles.select}
                        >
                            <option value="all">All Roles</option>
                            <option value="user">Users Only</option>
                            <option value="worker">Workers Only</option>
                        </select>
                    </div>

                    <div style={styles.selectWrapper}>
                        <Filter size={14} style={styles.selectIcon} />
                        <select
                            value={statusFilter}
                            onChange={(e) => setStatusFilter(e.target.value)}
                            style={styles.select}
                        >
                            <option value="all">All Statuses</option>
                            <option value="pending">Pending</option>
                            <option value="in-progress">In Progress</option>
                            <option value="resolved">Resolved</option>
                        </select>
                    </div>
                </div>
            </div>

            <div style={styles.tableCard}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Requester Info</th>
                            <th style={styles.th}>Role</th>
                            <th style={styles.th}>Subject</th>
                            <th style={styles.th}>Status</th>
                            <th style={styles.th}>Submitted On</th>
                            <th style={styles.th}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredRequests.length === 0 ? (
                            <tr>
                                <td colSpan="6" style={styles.noData}>
                                    No help requests found.
                                </td>
                            </tr>
                        ) : (
                            filteredRequests.map((req) => {
                                const statusInfo = getStatusBadge(req.status);
                                const roleInfo = getRoleBadge(req.role);
                                return (
                                    <tr key={req._id} style={styles.tr}>
                                        <td style={styles.td}>
                                            <div style={styles.userCell}>
                                                <div style={{
                                                    ...styles.avatar,
                                                    background: req.role === 'worker' ? '#e6f4ea' : '#e8f0fe',
                                                    color: req.role === 'worker' ? '#137333' : '#1a73e8'
                                                }}>
                                                    {req.name.charAt(0)}
                                                </div>
                                                <div style={styles.userInfo}>
                                                    <span style={styles.userName}>{req.name}</span>
                                                    {req.email && (
                                                        <span style={styles.userEmail}>
                                                            <Mail size={12} style={{ marginRight: 4 }} /> {req.email}
                                                        </span>
                                                    )}
                                                    {req.phone && (
                                                        <span style={styles.userPhone}>
                                                            <Phone size={12} style={{ marginRight: 4 }} /> {req.phone}
                                                        </span>
                                                    )}
                                                </div>
                                            </div>
                                        </td>
                                        <td style={styles.td}>
                                            <span style={{
                                                ...styles.roleBadge,
                                                background: roleInfo.background,
                                                color: roleInfo.color,
                                                border: roleInfo.border
                                            }}>
                                                {roleInfo.label}
                                            </span>
                                        </td>
                                        <td style={styles.td}>
                                            <div style={styles.subjectCell}>
                                                <span style={styles.subjectText}>{req.subject}</span>
                                                <span style={styles.messageTextPreview}>{req.message}</span>
                                            </div>
                                        </td>
                                        <td style={styles.td}>
                                            <div style={{
                                                ...styles.statusBadge,
                                                background: statusInfo.background,
                                                color: statusInfo.color
                                            }}>
                                                {statusInfo.icon}
                                                <span style={{ marginLeft: 6 }}>{statusInfo.label}</span>
                                            </div>
                                        </td>
                                        <td style={styles.td}>
                                            <div style={styles.dateCell}>
                                                <Calendar size={14} style={{ marginRight: 6 }} />
                                                {new Date(req.createdAt).toLocaleString()}
                                            </div>
                                        </td>
                                        <td style={styles.td}>
                                            <div style={styles.actionGroup}>
                                                <button
                                                    onClick={() => setSelectedRequest(req)}
                                                    style={styles.viewBtn}
                                                    title="View Details"
                                                >
                                                    <Eye size={18} />
                                                </button>
                                                {req.status !== 'resolved' && (
                                                    <button
                                                        onClick={() => handleUpdateStatus(req._id, 'resolved')}
                                                        style={styles.resolveBtn}
                                                        title="Mark as Resolved"
                                                    >
                                                        <CheckCircle size={18} />
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })
                        )}
                    </tbody>
                </table>
            </div>

            {/* Ticket Details Modal */}
            {selectedRequest && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modalContent}>
                        <div style={styles.modalHeader}>
                            <h2 style={styles.modalTitle}>Ticket Details</h2>
                            <button onClick={() => setSelectedRequest(null)} style={styles.closeBtn}>
                                <X size={20} />
                            </button>
                        </div>

                        <div style={styles.modalBody}>
                            <div style={styles.modalSection}>
                                <h4 style={styles.modalLabel}>Requester Info</h4>
                                <div style={styles.modalRequester}>
                                    <p><strong>Name:</strong> {selectedRequest.name}</p>
                                    {selectedRequest.email && <p><strong>Email:</strong> {selectedRequest.email}</p>}
                                    {selectedRequest.phone && <p><strong>Phone:</strong> {selectedRequest.phone}</p>}
                                    <p>
                                        <strong>Role:</strong>{' '}
                                        <span style={{
                                            ...styles.roleBadge,
                                            padding: '0.2rem 0.5rem',
                                            ...getRoleBadge(selectedRequest.role)
                                        }}>
                                            {selectedRequest.role.toUpperCase()}
                                        </span>
                                    </p>
                                </div>
                            </div>

                            <div style={styles.modalSection}>
                                <h4 style={styles.modalLabel}>Ticket Meta</h4>
                                <p><strong>Status:</strong>{' '}
                                    <span style={{
                                        ...styles.statusBadge,
                                        display: 'inline-flex',
                                        ...getStatusBadge(selectedRequest.status)
                                    }}>
                                        {getStatusBadge(selectedRequest.status).label}
                                    </span>
                                </p>
                                <p><strong>Submitted On:</strong> {new Date(selectedRequest.createdAt).toLocaleString()}</p>
                            </div>

                            <div style={styles.modalSection}>
                                <h4 style={styles.modalLabel}>Subject</h4>
                                <p style={styles.modalSubject}>{selectedRequest.subject}</p>
                            </div>

                            <div style={styles.modalSection}>
                                <h4 style={styles.modalLabel}>Message / Description</h4>
                                <div style={styles.modalMessage}>{selectedRequest.message}</div>
                            </div>
                        </div>

                        <div style={styles.modalFooter}>
                            <div style={styles.modalActionGroup}>
                                <button
                                    onClick={() => handleUpdateStatus(selectedRequest._id, 'pending')}
                                    style={{
                                        ...styles.actionBtn,
                                        background: selectedRequest.status === 'pending' ? '#d1d5db' : '#f3f4f6',
                                        color: '#374151'
                                    }}
                                >
                                    Mark Pending
                                </button>
                                <button
                                    onClick={() => handleUpdateStatus(selectedRequest._id, 'in-progress')}
                                    style={{
                                        ...styles.actionBtn,
                                        background: selectedRequest.status === 'in-progress' ? '#bae6fd' : '#e0f2fe',
                                        color: '#0369a1'
                                    }}
                                >
                                    Mark In Progress
                                </button>
                                <button
                                    onClick={() => handleUpdateStatus(selectedRequest._id, 'resolved')}
                                    style={{
                                        ...styles.actionBtn,
                                        background: selectedRequest.status === 'resolved' ? '#bbf7d0' : '#dcfce7',
                                        color: '#15803d'
                                    }}
                                >
                                    Mark Resolved
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
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
        justifyContent: 'space-between',
        flexWrap: 'wrap',
    },
    searchWrapper: {
        position: 'relative',
        flex: 1,
        maxWidth: '400px',
        minWidth: '280px',
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
        fontSize: '0.9rem',
    },
    filterGroup: {
        display: 'flex',
        gap: '1rem',
    },
    selectWrapper: {
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
    },
    selectIcon: {
        position: 'absolute',
        left: '1rem',
        color: '#94a3b8',
        pointerEvents: 'none',
    },
    select: {
        padding: '0.75rem 1rem 0.75rem 2.5rem',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        background: 'white',
        outline: 'none',
        cursor: 'pointer',
        fontSize: '0.9rem',
        color: '#475569',
        minWidth: '150px',
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
        borderRadius: '12px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: '700',
        fontSize: '1.2rem',
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
        marginTop: '2px',
    },
    userPhone: {
        fontSize: '0.8rem',
        color: '#64748b',
        display: 'flex',
        alignItems: 'center',
        marginTop: '2px',
    },
    roleBadge: {
        padding: '0.35rem 0.75rem',
        borderRadius: '100px',
        fontSize: '0.7rem',
        fontWeight: '700',
        textTransform: 'uppercase',
        display: 'inline-flex',
        alignItems: 'center',
        width: 'fit-content',
    },
    subjectCell: {
        display: 'flex',
        flexDirection: 'column',
        maxWidth: '300px',
    },
    subjectText: {
        fontWeight: '700',
        color: '#1e293b',
        whiteSpace: 'nowrap',
        overflow: 'hidden',
        textOverflow: 'ellipsis',
    },
    messageTextPreview: {
        fontSize: '0.8rem',
        color: '#64748b',
        whiteSpace: 'nowrap',
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        marginTop: '2px',
    },
    statusBadge: {
        padding: '0.35rem 0.75rem',
        borderRadius: '100px',
        fontSize: '0.7rem',
        fontWeight: '700',
        textTransform: 'uppercase',
        display: 'inline-flex',
        alignItems: 'center',
        width: 'fit-content',
    },
    dateCell: {
        display: 'flex',
        alignItems: 'center',
        color: '#64748b',
        fontSize: '0.85rem',
    },
    actionGroup: {
        display: 'flex',
        gap: '0.5rem',
    },
    viewBtn: {
        background: '#f1f5f9',
        border: 'none',
        color: '#475569',
        width: '36px',
        height: '36px',
        borderRadius: '10px',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'all 0.2s',
    },
    resolveBtn: {
        background: '#dcfce7',
        border: 'none',
        color: '#15803d',
        width: '36px',
        height: '36px',
        borderRadius: '10px',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'all 0.2s',
    },
    noData: {
        textAlign: 'center',
        padding: '3rem',
        color: '#64748b',
        fontSize: '0.95rem',
    },
    loading: {
        display: 'flex',
        height: '100%',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: '1.1rem',
        color: '#64748b',
        fontWeight: '500',
    },
    // Modal styles
    modalOverlay: {
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(15, 23, 42, 0.4)',
        backdropFilter: 'blur(4px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        padding: '1.5rem',
    },
    modalContent: {
        background: 'white',
        borderRadius: '24px',
        width: '100%',
        maxWidth: '600px',
        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        maxHeight: '85vh',
    },
    modalHeader: {
        padding: '1.5rem 2rem',
        borderBottom: '1px solid #f1f5f9',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    modalTitle: {
        margin: 0,
        fontSize: '1.35rem',
        fontWeight: '800',
        color: '#1e293b',
    },
    closeBtn: {
        background: 'transparent',
        border: 'none',
        color: '#94a3b8',
        cursor: 'pointer',
        padding: '0.25rem',
        borderRadius: '8px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'all 0.2s',
    },
    modalBody: {
        padding: '2rem',
        overflowY: 'auto',
        display: 'flex',
        flexDirection: 'column',
        gap: '1.5rem',
    },
    modalSection: {
        display: 'flex',
        flexDirection: 'column',
        gap: '0.5rem',
    },
    modalLabel: {
        margin: 0,
        fontSize: '0.8rem',
        fontWeight: '700',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        color: '#94a3b8',
    },
    modalRequester: {
        background: '#f8fafc',
        padding: '1rem 1.25rem',
        borderRadius: '12px',
        display: 'flex',
        flexDirection: 'column',
        gap: '0.4rem',
        fontSize: '0.9rem',
        color: '#334155',
        border: '1px solid #f1f5f9',
    },
    modalSubject: {
        margin: 0,
        fontSize: '1.1rem',
        fontWeight: '700',
        color: '#1e293b',
    },
    modalMessage: {
        fontSize: '0.95rem',
        lineHeight: '1.6',
        color: '#334155',
        whiteSpace: 'pre-wrap',
        background: '#f8fafc',
        padding: '1.25rem',
        borderRadius: '12px',
        border: '1px solid #f1f5f9',
        maxHeight: '200px',
        overflowY: 'auto',
    },
    modalFooter: {
        padding: '1.5rem 2rem',
        borderTop: '1px solid #f1f5f9',
        background: '#f8fafc',
    },
    modalActionGroup: {
        display: 'flex',
        gap: '1rem',
        justifyContent: 'flex-end',
    },
    actionBtn: {
        padding: '0.6rem 1.25rem',
        borderRadius: '10px',
        border: 'none',
        fontWeight: '600',
        fontSize: '0.85rem',
        cursor: 'pointer',
        transition: 'all 0.2s',
    }
};

export default HelpRequests;
