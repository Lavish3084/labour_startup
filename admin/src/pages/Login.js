import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Lock, Mail, Loader2 } from 'lucide-react';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);
        try {
            await login(email, password);
            navigate('/');
        } catch (err) {
            setError(err.response?.data?.msg || err.message || 'Login failed');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div style={styles.container}>
            <div style={styles.glassCard}>
                <div style={styles.header}>
                    <h1 style={styles.title}>Labour Market</h1>
                    <p style={styles.subtitle}>Admin Dashboard</p>
                </div>

                {error && <div style={styles.error}>{error}</div>}

                <form onSubmit={handleSubmit} style={styles.form}>
                    <div style={styles.inputGroup}>
                        <Mail size={18} style={styles.icon} />
                        <input
                            type="email"
                            placeholder="Email Address"
                            style={styles.input}
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                        />
                    </div>

                    <div style={styles.inputGroup}>
                        <Lock size={18} style={styles.icon} />
                        <input
                            type="password"
                            placeholder="Password"
                            style={styles.input}
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>

                    <button
                        type="submit"
                        disabled={isLoading}
                        style={{
                            ...styles.button,
                            opacity: isLoading ? 0.7 : 1,
                        }}
                    >
                        {isLoading ? (
                            <Loader2 style={styles.spinner} />
                        ) : (
                            'Sign In'
                        )}
                    </button>
                </form>
            </div>
            <div style={styles.backgroundBlobs}>
                <div style={styles.blob1}></div>
                <div style={styles.blob2}></div>
            </div>
        </div>
    );
};

const styles = {
    container: {
        height: '100vh',
        width: '100vw',
        background: '#f8fafc',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: "'Inter', sans-serif",
    },
    glassCard: {
        background: 'rgba(255, 255, 255, 0.9)',
        backdropFilter: 'blur(10px)',
        border: '1px solid rgba(255, 255, 255, 0.2)',
        borderRadius: '24px',
        padding: '2.5rem',
        width: '100%',
        maxWidth: '400px',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.05)',
        zIndex: 10,
    },
    header: {
        textAlign: 'center',
        marginBottom: '2rem',
    },
    title: {
        fontSize: '1.8rem',
        fontWeight: '800',
        color: '#1e293b',
        margin: 0,
        letterSpacing: '-0.5px',
    },
    subtitle: {
        fontSize: '0.9rem',
        color: '#64748b',
        marginTop: '0.2rem',
    },
    form: {
        display: 'flex',
        flexDirection: 'column',
        gap: '1.2rem',
    },
    inputGroup: {
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
    },
    icon: {
        position: 'absolute',
        left: '1rem',
        color: '#94a3b8',
    },
    input: {
        width: '100%',
        padding: '1rem 1rem 1rem 3rem',
        background: '#f1f5f9',
        border: '1px solid #e2e8f0',
        borderRadius: '12px',
        fontSize: '0.95rem',
        color: '#1e293b',
        outline: 'none',
        transition: 'all 0.2s ease',
    },
    button: {
        marginTop: '0.5rem',
        padding: '1rem',
        background: '#1e293b',
        color: 'white',
        border: 'none',
        borderRadius: '12px',
        fontSize: '1rem',
        fontWeight: '600',
        cursor: 'pointer',
        transition: 'all 0.2s ease',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
    },
    error: {
        background: '#fef2f2',
        color: '#ef4444',
        padding: '0.8rem',
        borderRadius: '10px',
        fontSize: '0.85rem',
        marginBottom: '1rem',
        textAlign: 'center',
        border: '1px solid #fee2e2',
    },
    spinner: {
        animation: 'spin 1s linear infinite',
    },
    backgroundBlobs: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 1,
    },
    blob1: {
        position: 'absolute',
        top: '10%',
        right: '10%',
        width: '300px',
        height: '300px',
        background: 'linear-gradient(135deg, #e0f2fe 0%, #bae6fd 100%)',
        borderRadius: '50%',
        filter: 'blur(80px)',
        opacity: 0.6,
    },
    blob2: {
        position: 'absolute',
        bottom: '10%',
        left: '10%',
        width: '350px',
        height: '350px',
        background: 'linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%)',
        borderRadius: '50%',
        filter: 'blur(100px)',
        opacity: 0.5,
    },
};

export default Login;
