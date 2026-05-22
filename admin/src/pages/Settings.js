import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { Settings as SettingsIcon, Save, MapPin, Plus, Trash2, Navigation, ChevronDown, ChevronUp } from 'lucide-react';

const Settings = () => {
    const [settings, setSettings] = useState({ adminCommissionPercentage: 0, cancellationRefundPercentage: 50, enabledCities: '' });
    const [serviceZones, setServiceZones] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState({ type: '', text: '' });

    // New zone form state
    const [newZoneName, setNewZoneName] = useState('');
    const [newZoneRadius, setNewZoneRadius] = useState(15);
    const [isGeocoding, setIsGeocoding] = useState(false);
    const [showLegacy, setShowLegacy] = useState(false);

    useEffect(() => {
        fetchSettings();
    }, []);

    const fetchSettings = async () => {
        try {
            const res = await api.get('/settings');
            setSettings({
                adminCommissionPercentage: res.data.adminCommissionPercentage || 0,
                cancellationRefundPercentage: res.data.cancellationRefundPercentage ?? 50,
                enabledCities: res.data.enabledCities || '',
            });

            // Parse serviceZones
            let zones = [];
            if (res.data.serviceZones) {
                if (typeof res.data.serviceZones === 'string') {
                    try { zones = JSON.parse(res.data.serviceZones); } catch (e) { zones = []; }
                } else if (Array.isArray(res.data.serviceZones)) {
                    zones = res.data.serviceZones;
                }
            }
            setServiceZones(zones);
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
            await api.put('/settings', {
                ...settings,
                serviceZones: serviceZones,
            });
            setMessage({ type: 'success', text: 'Settings updated successfully!' });
        } catch (err) {
            console.error('Error saving settings:', err);
            setMessage({ type: 'error', text: err.response?.data?.msg || 'Failed to update settings' });
        } finally {
            setSaving(false);
        }
    };

    const handleAddZone = async () => {
        if (!newZoneName.trim()) return;

        setIsGeocoding(true);
        try {
            // Use OpenStreetMap Nominatim for free geocoding (no API key needed)
            const response = await fetch(
                `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(newZoneName.trim())}&format=json&limit=1`,
                { headers: { 'User-Agent': 'LabourApp/1.0' } }
            );
            const data = await response.json();

            if (data && data.length > 0) {
                const { lat, lon, display_name } = data[0];
                const newZone = {
                    id: Date.now().toString(),
                    name: newZoneName.trim(),
                    fullName: display_name,
                    lat: parseFloat(lat),
                    lng: parseFloat(lon),
                    radiusKm: newZoneRadius,
                };
                setServiceZones(prev => [...prev, newZone]);
                setNewZoneName('');
                setNewZoneRadius(15);
                setMessage({ type: 'success', text: `Zone "${newZone.name}" added at (${newZone.lat.toFixed(4)}, ${newZone.lng.toFixed(4)}). Don't forget to Save Changes!` });
            } else {
                setMessage({ type: 'error', text: `Could not find coordinates for "${newZoneName}". Try a more specific name (e.g., "Mohali, Punjab, India").` });
            }
        } catch (err) {
            console.error('Geocoding error:', err);
            setMessage({ type: 'error', text: 'Geocoding failed. Check your internet connection.' });
        } finally {
            setIsGeocoding(false);
        }
    };

    const handleRemoveZone = (zoneId) => {
        setServiceZones(prev => prev.filter(z => z.id !== zoneId));
        setMessage({ type: 'success', text: 'Zone removed. Don\'t forget to Save Changes!' });
    };

    const handleRadiusChange = (zoneId, newRadius) => {
        setServiceZones(prev => prev.map(z =>
            z.id === zoneId ? { ...z, radiusKm: parseFloat(newRadius) || 15 } : z
        ));
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

            {/* Commission Configuration Card */}
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

                    <div style={styles.formGroup}>
                        <label style={styles.label}>Cancellation Refund Percentage (%)</label>
                        <p style={styles.helpText}>Percentage of platform fee refunded to user if they cancel after a worker accepted.</p>
                        <input
                            type="number"
                            min="0"
                            max="100"
                            step="1"
                            value={settings.cancellationRefundPercentage}
                            onChange={(e) => setSettings({ ...settings, cancellationRefundPercentage: e.target.value })}
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

            {/* Service Zones Card */}
            <div style={{ ...styles.card, marginTop: '24px' }}>
                <div style={styles.cardHeader}>
                    <MapPin size={20} style={{ color: '#10b981' }} />
                    <h2 style={styles.cardTitle}>Service Zones (Coordinate-Based)</h2>
                </div>

                <p style={styles.helpText}>
                    Define active service areas using GPS coordinates. Enter a city name and we'll auto-detect its coordinates. 
                    Adjust the radius to control how far from the city center your service extends.
                </p>

                {/* Add Zone Form */}
                <div style={styles.addZoneForm}>
                    <div style={styles.addZoneRow}>
                        <div style={{ flex: 1 }}>
                            <label style={styles.label}>City / Area Name</label>
                            <div style={styles.inputWithIcon}>
                                <Navigation size={16} style={styles.inputIcon} />
                                <input
                                    type="text"
                                    placeholder="e.g., Mohali, Punjab, India"
                                    value={newZoneName}
                                    onChange={(e) => setNewZoneName(e.target.value)}
                                    style={{ ...styles.input, maxWidth: '100%', paddingLeft: '40px' }}
                                    onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddZone())}
                                />
                            </div>
                        </div>
                        <div style={{ width: '140px' }}>
                            <label style={styles.label}>Radius (km)</label>
                            <input
                                type="number"
                                min="1"
                                max="100"
                                step="1"
                                value={newZoneRadius}
                                onChange={(e) => setNewZoneRadius(parseInt(e.target.value) || 15)}
                                style={{ ...styles.input, maxWidth: '100%' }}
                            />
                        </div>
                        <div style={{ alignSelf: 'flex-end' }}>
                            <button
                                type="button"
                                onClick={handleAddZone}
                                disabled={isGeocoding || !newZoneName.trim()}
                                style={{
                                    ...styles.addBtn,
                                    opacity: (isGeocoding || !newZoneName.trim()) ? 0.5 : 1,
                                    cursor: (isGeocoding || !newZoneName.trim()) ? 'not-allowed' : 'pointer',
                                }}
                            >
                                <Plus size={18} />
                                {isGeocoding ? 'Locating...' : 'Add Zone'}
                            </button>
                        </div>
                    </div>

                    {/* Radius Visual Hint */}
                    <div style={styles.radiusHint}>
                        <span style={styles.radiusHintIcon}>📍</span>
                        <span>Tip: 15 km covers most Indian tier-2/3 cities. Use 25–50 km for metro areas.</span>
                    </div>
                </div>

                {/* Active Zones List */}
                {serviceZones.length > 0 && (
                    <div style={styles.zonesTable}>
                        <div style={styles.zonesTableHeader}>
                            <span style={{ flex: 2 }}>Zone Name</span>
                            <span style={{ flex: 2 }}>Coordinates</span>
                            <span style={{ flex: 1 }}>Radius</span>
                            <span style={{ width: '60px', textAlign: 'center' }}>Action</span>
                        </div>
                        {serviceZones.map((zone, index) => (
                            <div key={zone.id || index} style={styles.zoneRow}>
                                <div style={{ flex: 2 }}>
                                    <span style={styles.zoneName}>{zone.name}</span>
                                    {zone.fullName && (
                                        <span style={styles.zoneFullName}>{zone.fullName}</span>
                                    )}
                                </div>
                                <div style={{ flex: 2 }}>
                                    <span style={styles.zoneCoords}>
                                        {parseFloat(zone.lat).toFixed(4)}, {parseFloat(zone.lng).toFixed(4)}
                                    </span>
                                </div>
                                <div style={{ flex: 1 }}>
                                    <div style={styles.radiusInputWrap}>
                                        <input
                                            type="number"
                                            min="1"
                                            max="100"
                                            value={zone.radiusKm}
                                            onChange={(e) => handleRadiusChange(zone.id, e.target.value)}
                                            style={styles.radiusInput}
                                        />
                                        <span style={styles.radiusUnit}>km</span>
                                    </div>
                                </div>
                                <div style={{ width: '60px', textAlign: 'center' }}>
                                    <button
                                        onClick={() => handleRemoveZone(zone.id)}
                                        style={styles.deleteBtn}
                                        title="Remove zone"
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {serviceZones.length === 0 && (
                    <div style={styles.emptyZones}>
                        <MapPin size={32} style={{ color: '#cbd5e1', marginBottom: '8px' }} />
                        <p style={{ margin: 0, color: '#94a3b8', fontSize: '14px' }}>No service zones configured.</p>
                        <p style={{ margin: '4px 0 0 0', color: '#cbd5e1', fontSize: '13px' }}>All locations will be active by default.</p>
                    </div>
                )}

                {/* Save Zones Button */}
                <button
                    type="button"
                    onClick={handleSave}
                    disabled={saving}
                    style={{ ...styles.saveBtn, marginTop: '20px' }}
                >
                    <Save size={18} />
                    {saving ? 'Saving...' : 'Save All Settings'}
                </button>

                {/* Legacy Fallback Toggle */}
                <div style={styles.legacyToggle}>
                    <button
                        type="button"
                        onClick={() => setShowLegacy(!showLegacy)}
                        style={styles.legacyToggleBtn}
                    >
                        {showLegacy ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                        <span>Legacy City Text Fallback (Advanced)</span>
                    </button>
                    {showLegacy && (
                        <div style={{ marginTop: '12px' }}>
                            <p style={styles.helpText}>
                                Comma-separated city names. Only used as fallback when no coordinate-based zones are configured.
                            </p>
                            <textarea
                                value={settings.enabledCities}
                                onChange={(e) => setSettings({ ...settings, enabledCities: e.target.value })}
                                style={{
                                    ...styles.input,
                                    maxWidth: '100%',
                                    minHeight: '60px',
                                    fontFamily: 'inherit',
                                    resize: 'vertical'
                                }}
                                placeholder="e.g., Mohali, Chandigarh"
                            />
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

const styles = {
    container: { padding: '24px', maxWidth: '900px' },
    header: { marginBottom: '24px' },
    title: { fontSize: '24px', fontWeight: 'bold', color: '#1e293b', margin: '0 0 8px 0' },
    subtitle: { color: '#64748b', margin: 0 },
    card: {
        background: 'white',
        borderRadius: '16px',
        border: '1px solid #e2e8f0',
        padding: '28px',
        boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.06), 0 1px 2px -1px rgba(0, 0, 0, 0.06)'
    },
    cardHeader: {
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        marginBottom: '20px',
        paddingBottom: '16px',
        borderBottom: '1px solid #f1f5f9'
    },
    cardTitle: { fontSize: '18px', fontWeight: '700', color: '#1e293b', margin: 0 },
    form: { display: 'flex', flexDirection: 'column', gap: '24px' },
    formGroup: { display: 'flex', flexDirection: 'column', gap: '8px' },
    label: { fontSize: '14px', fontWeight: '600', color: '#334155' },
    helpText: { fontSize: '13px', color: '#64748b', margin: '0 0 8px 0', lineHeight: '1.5' },
    input: {
        padding: '10px 12px',
        borderRadius: '10px',
        border: '1px solid #e2e8f0',
        fontSize: '15px',
        width: '100%',
        maxWidth: '300px',
        outline: 'none',
        transition: 'border-color 0.2s',
    },
    inputWithIcon: {
        position: 'relative',
    },
    inputIcon: {
        position: 'absolute',
        left: '12px',
        top: '50%',
        transform: 'translateY(-50%)',
        color: '#94a3b8',
        pointerEvents: 'none',
    },
    saveBtn: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '8px',
        backgroundColor: '#3b82f6',
        color: 'white',
        padding: '12px 24px',
        borderRadius: '10px',
        border: 'none',
        fontSize: '15px',
        fontWeight: '600',
        cursor: 'pointer',
        alignSelf: 'flex-start',
        transition: 'all 0.2s',
    },
    addBtn: {
        display: 'flex',
        alignItems: 'center',
        gap: '6px',
        backgroundColor: '#10b981',
        color: 'white',
        padding: '10px 20px',
        borderRadius: '10px',
        border: 'none',
        fontSize: '14px',
        fontWeight: '600',
        cursor: 'pointer',
        transition: 'all 0.2s',
        whiteSpace: 'nowrap',
    },
    addZoneForm: {
        background: '#f8fafc',
        borderRadius: '12px',
        padding: '20px',
        marginBottom: '20px',
        border: '1px solid #e2e8f0',
    },
    addZoneRow: {
        display: 'flex',
        gap: '16px',
        alignItems: 'flex-start',
        flexWrap: 'wrap',
    },
    radiusHint: {
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        marginTop: '12px',
        padding: '8px 12px',
        background: '#fffbeb',
        borderRadius: '8px',
        fontSize: '13px',
        color: '#92400e',
        border: '1px solid #fde68a',
    },
    radiusHintIcon: {
        fontSize: '14px',
    },
    zonesTable: {
        border: '1px solid #e2e8f0',
        borderRadius: '12px',
        overflowX: 'auto',
        marginBottom: '4px',
    },
    zonesTableHeader: {
        display: 'flex',
        alignItems: 'center',
        padding: '12px 16px',
        background: '#f8fafc',
        borderBottom: '1px solid #e2e8f0',
        fontSize: '12px',
        fontWeight: '700',
        color: '#64748b',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        minWidth: '600px',
    },
    zoneRow: {
        display: 'flex',
        alignItems: 'center',
        padding: '14px 16px',
        borderBottom: '1px solid #f1f5f9',
        fontSize: '14px',
        transition: 'background 0.15s',
        minWidth: '600px',
    },
    zoneName: {
        fontWeight: '700',
        color: '#1e293b',
        display: 'block',
    },
    zoneFullName: {
        fontSize: '12px',
        color: '#94a3b8',
        display: 'block',
        marginTop: '2px',
        maxWidth: '250px',
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap',
    },
    zoneCoords: {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#475569',
        background: '#f1f5f9',
        padding: '4px 8px',
        borderRadius: '6px',
    },
    radiusInputWrap: {
        display: 'flex',
        alignItems: 'center',
        gap: '4px',
    },
    radiusInput: {
        width: '60px',
        padding: '6px 8px',
        borderRadius: '8px',
        border: '1px solid #e2e8f0',
        fontSize: '14px',
        textAlign: 'center',
        outline: 'none',
    },
    radiusUnit: {
        fontSize: '13px',
        color: '#94a3b8',
        fontWeight: '500',
    },
    deleteBtn: {
        background: 'transparent',
        border: 'none',
        color: '#ef4444',
        cursor: 'pointer',
        padding: '6px',
        borderRadius: '8px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'all 0.15s',
    },
    emptyZones: {
        textAlign: 'center',
        padding: '32px 20px',
        background: '#f8fafc',
        borderRadius: '12px',
        border: '1px dashed #e2e8f0',
    },
    legacyToggle: {
        marginTop: '20px',
        paddingTop: '16px',
        borderTop: '1px solid #f1f5f9',
    },
    legacyToggleBtn: {
        background: 'transparent',
        border: 'none',
        display: 'flex',
        alignItems: 'center',
        gap: '6px',
        fontSize: '13px',
        color: '#94a3b8',
        cursor: 'pointer',
        padding: 0,
        fontWeight: '500',
    },
    loading: { padding: '40px', textAlign: 'center', color: '#64748b' },
    errorMsg: { padding: '12px 16px', borderRadius: '10px', backgroundColor: '#fef2f2', color: '#ef4444', marginBottom: '20px', fontSize: '14px', border: '1px solid #fecaca' },
    successMsg: { padding: '12px 16px', borderRadius: '10px', backgroundColor: '#f0fdf4', color: '#22c55e', marginBottom: '20px', fontSize: '14px', border: '1px solid #bbf7d0' },
};

export default Settings;
