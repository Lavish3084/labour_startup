import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import { Settings as SettingsIcon, Save } from 'lucide-react';

const Settings = () => {
    const { token } = useAuth();
    const [settings, setSettings] = useState({ adminCommissionPercentage: 0 });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState({ type: '', text: '' });

    useEffect(() => {
        fetchSettings();
    }, []);

    const fetchSettings = async () => {
        try {
            const res = await axios.get(`${process.env.REACT_APP_API_URL || 'http://localhost:5000/api'}/settings`);
            // Initialize with default or retrieved values
            setSettings({
                adminCommissionPercentage: res.data.adminCommissionPercentage || 0,
            });
            setLoading(false);
        } catch (err) {
            console.error('Error fetching settings:', err);
            setMessage({ type: 'error', text: 'Failed to load settings' });
            setLoading(false);
        }
    };

    const handleSave = async (e) => {
        e.preventDefault();
        setSaving(true);
        setMessage({ type: '', text: '' });

        try {
            await axios.put(
                `${process.env.REACT_APP_API_URL || 'http://localhost:5000/api'}/settings`,
                settings,
                { headers: { 'x-auth-token': token } }
            );
            setMessage({ type: 'success', text: 'Settings updated successfully!' });
        } catch (err) {
            console.error('Error saving settings:', err);
            setMessage({ type: 'error', text: err.response?.data?.msg || 'Failed to update settings' });
        } finally {
            setSaving(false);
        }
    };

    if (loading) return <div style={styles.loading}>Loading settings...</div>;

    return (
        <div style={styles.container}>
            <div style={styles.header}>
                <div>
                    <h1 style={styles.title}>System Settings</h1>
                    <p style={styles.subtitle}>Manage global application settings</p>
                </div>
            </div>

            {message.text && (
                <div style={message.type === 'error' ? styles.errorMsg : styles.successMsg}>
                    {message.text}
                </div>
            )}

            <div style={styles.card}>
                <div style={styles.cardHeader}>
                    <SettingsIcon size={20} style={{ color: '#64748b' }} />
                    <h2 style={styles.cardTitle}>Commission Configuration</h2>
                </div>
                
                <form onSubmit={handleSave} style={styles.form}>
                    <div style={styles.formGroup}>
                        <label style={styles.label}>Admin Commission Percentage (%)</label>
                        <p style={styles.helpText}>This percentage is deducted from the worker's total payout.</p>
                        <input
                            type="number"
                            min="0"
                            max="100"
                            step="0.1"
                            value={settings.adminCommissionPercentage}
                            onChange={(e) => setSettings({ ...settings, adminCommissionPercentage: e.target.value })}
                            style={styles.input}
                            required
                        />
                    </div>

                    <button type="submit" disabled={saving} style={styles.saveBtn}>
                        <Save size={18} />
                        {saving ? 'Saving...' : 'Save Changes'}
                    </button>
                </form>
            </div>
        </div>
    );
};

const styles = {
    container: { padding: '24px', maxWidth: '800px' },
    header: { marginBottom: '24px' },
    title: { fontSize: '24px', fontWeight: 'bold', color: '#1e293b', margin: '0 0 8px 0' },
    subtitle: { color: '#64748b', margin: 0 },
    card: {
        background: 'white',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        padding: '24px',
        boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)'
    },
    cardHeader: {
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        marginBottom: '24px',
        paddingBottom: '16px',
        borderBottom: '1px solid #e2e8f0'
    },
    cardTitle: { fontSize: '18px', fontWeight: '600', color: '#1e293b', margin: 0 },
    form: { display: 'flex', flexDirection: 'column', gap: '24px' },
    formGroup: { display: 'flex', flexDirection: 'column', gap: '8px' },
    label: { fontSize: '14px', fontWeight: '600', color: '#334155' },
    helpText: { fontSize: '13px', color: '#64748b', margin: '0 0 4px 0' },
    input: {
        padding: '10px 12px',
        borderRadius: '8px',
        border: '1px solid #e2e8f0',
        fontSize: '15px',
        width: '100%',
        maxWidth: '300px',
        outline: 'none',
        transition: 'border-color 0.2s',
    },
    saveBtn: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '8px',
        backgroundColor: '#3b82f6',
        color: 'white',
        padding: '12px 24px',
        borderRadius: '8px',
        border: 'none',
        fontSize: '15px',
        fontWeight: '600',
        cursor: 'pointer',
        alignSelf: 'flex-start',
        transition: 'background-color 0.2s',
    },
    loading: { padding: '40px', textAlign: 'center', color: '#64748b' },
    errorMsg: { padding: '12px', borderRadius: '8px', backgroundColor: '#fef2f2', color: '#ef4444', marginBottom: '20px', fontSize: '14px' },
    successMsg: { padding: '12px', borderRadius: '8px', backgroundColor: '#f0fdf4', color: '#22c55e', marginBottom: '20px', fontSize: '14px' },
};

export default Settings;
