import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import { IndianRupee, MapPin, CheckCircle, Clock } from 'lucide-react';

const Payouts = () => {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const { token } = useAuth();
    const [processingId, setProcessingId] = useState(null);

    useEffect(() => {
        fetchPayouts();
    }, []);

    const fetchPayouts = async () => {
        try {
            const res = await axios.get(`${process.env.REACT_APP_API_URL || 'http://localhost:5000/api'}/admin/bookings`, {
                headers: { 'x-auth-token': token }
            });
            // Filter bookings that have work confirmed but not released yet (or show all and just style them)
            // Let's just show all completed/confirmed work bookings
            const payoutBookings = res.data.filter(b => b.isWorkConfirmed);
            setBookings(payoutBookings);
            setLoading(false);
        } catch (err) {
            console.error('Error fetching payouts:', err);
            setLoading(false);
        }
    };

    const handleReleasePayout = async (id) => {
        if (!window.confirm('Are you sure you want to mark this payout as released?')) return;
        
        setProcessingId(id);
        try {
            await axios.put(
                `${process.env.REACT_APP_API_URL || 'http://localhost:5000/api'}/bookings/${id}/payout`,
                {},
                { headers: { 'x-auth-token': token } }
            );
            // Refresh list
            fetchPayouts();
        } catch (err) {
            console.error('Error releasing payout:', err);
            alert('Failed to release payout.');
        } finally {
            setProcessingId(null);
        }
    };

    if (loading) return <div style={styles.loading}>Loading payouts...</div>;

    return (
        <div style={styles.container}>
            <div style={styles.header}>
                <div>
                    <h1 style={styles.title}>Worker Payouts</h1>
                    <p style={styles.subtitle}>Manage and release payments to workers</p>
                </div>
            </div>

            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Booking Details</th>
                            <th style={styles.th}>Worker & UPI</th>
                            <th style={styles.th}>Amounts</th>
                            <th style={styles.th}>Status</th>
                            <th style={styles.th}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {bookings.length === 0 ? (
                            <tr>
                                <td colSpan="5" style={styles.emptyState}>No pending payouts found.</td>
                            </tr>
                        ) : (
                            bookings.map(booking => {
                                const isReleased = booking.paymentStatus === 'released';
                                const worker = booking.labourer || {};
                                
                                return (
                                    <tr key={booking._id} style={styles.tr}>
                                        <td style={styles.td}>
                                            <div style={styles.bold}>{booking.category}</div>
                                            <div style={styles.subtext}>
                                                <Clock size={12} style={{marginRight: 4}}/>
                                                {new Date(booking.date).toLocaleDateString()}
                                            </div>
                                        </td>
                                        <td style={styles.td}>
                                            <div style={styles.bold}>{worker.name || 'Unknown Worker'}</div>
                                            <div style={styles.subtext}>
                                                UPI: {worker.upiId || <span style={{color: '#f59e0b'}}>Not provided</span>}
                                            </div>
                                        </td>
                                        <td style={styles.td}>
                                            <div style={{...styles.bold, color: '#16a34a'}}>
                                                Payout: ₹{booking.workerPayoutAmount || 0}
                                            </div>
                                            <div style={styles.subtext}>
                                                Total: ₹{booking.amount || 0} | Comm: ₹{booking.commissionAmount || 0}
                                            </div>
                                        </td>
                                        <td style={styles.td}>
                                            {isReleased ? (
                                                <span style={styles.statusBadge.released}>Released</span>
                                            ) : (
                                                <span style={styles.statusBadge.pending}>Pending</span>
                                            )}
                                        </td>
                                        <td style={styles.td}>
                                            {!isReleased && (
                                                <button 
                                                    onClick={() => handleReleasePayout(booking._id)}
                                                    disabled={processingId === booking._id}
                                                    style={styles.actionBtn}
                                                >
                                                    {processingId === booking._id ? 'Processing...' : 'Mark as Paid'}
                                                </button>
                                            )}
                                        </td>
                                    </tr>
                                );
                            })
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const styles = {
    container: { padding: '24px', maxWidth: '1200px' },
    header: { marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' },
    title: { fontSize: '24px', fontWeight: 'bold', color: '#1e293b', margin: '0 0 8px 0' },
    subtitle: { color: '#64748b', margin: 0 },
    
    tableContainer: {
        background: 'white',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        overflow: 'hidden',
        boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
    },
    th: {
        background: '#f8fafc',
        padding: '16px',
        textAlign: 'left',
        fontSize: '13px',
        fontWeight: '600',
        color: '#475569',
        borderBottom: '1px solid #e2e8f0',
    },
    tr: {
        borderBottom: '1px solid #f1f5f9',
    },
    td: {
        padding: '16px',
        verticalAlign: 'middle',
    },
    bold: {
        fontWeight: '600',
        color: '#1e293b',
        fontSize: '14px',
        marginBottom: '4px'
    },
    subtext: {
        fontSize: '13px',
        color: '#64748b',
        display: 'flex',
        alignItems: 'center'
    },
    statusBadge: {
        pending: {
            display: 'inline-block',
            padding: '4px 10px',
            borderRadius: '9999px',
            fontSize: '12px',
            fontWeight: '600',
            backgroundColor: '#fef3c7',
            color: '#d97706',
        },
        released: {
            display: 'inline-block',
            padding: '4px 10px',
            borderRadius: '9999px',
            fontSize: '12px',
            fontWeight: '600',
            backgroundColor: '#dcfce3',
            color: '#16a34a',
        }
    },
    actionBtn: {
        padding: '6px 12px',
        backgroundColor: '#3b82f6',
        color: 'white',
        border: 'none',
        borderRadius: '6px',
        fontSize: '13px',
        fontWeight: '600',
        cursor: 'pointer',
        transition: 'background-color 0.2s'
    },
    loading: { padding: '40px', textAlign: 'center', color: '#64748b' },
    emptyState: { padding: '40px', textAlign: 'center', color: '#64748b', fontSize: '15px' },
};

export default Payouts;
