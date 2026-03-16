import React, { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
    LayoutDashboard,
    Tags,
    Users,
    ClipboardList,
    LogOut,
    Menu,
    X,
    Bell,
    Settings,
    UserCircle,
    Wallet
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

const Layout = ({ children }) => {
    const [isSidebarOpen, setIsSidebarOpen] = useState(true);
    const { logout, admin } = useAuth();
    const navigate = useNavigate();

    const menuItems = [
        { icon: <LayoutDashboard size={20} />, label: 'Dashboard', path: '/dashboard' },
        { icon: <Tags size={20} />, label: 'Categories', path: '/categories' },
        { icon: <ClipboardList size={20} />, label: 'Bookings', path: '/bookings' },
        { icon: <Wallet size={20} />, label: 'Payouts', path: '/payouts' },
        { icon: <Users size={20} />, label: 'Users', path: '/users' },
        { icon: <Settings size={20} />, label: 'Settings', path: '/settings' },
    ];

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    return (
        <div style={styles.container}>
            {/* Sidebar */}
            <aside style={{
                ...styles.sidebar,
                width: isSidebarOpen ? '260px' : '0',
                opacity: isSidebarOpen ? 1 : 0,
                transform: isSidebarOpen ? 'translateX(0)' : 'translateX(-100%)',
            }}>
                <div style={styles.logoContainer}>
                    <h2 style={styles.logoText}>Labour Admin</h2>
                </div>

                <nav style={styles.nav}>
                    {menuItems.map((item) => (
                        <NavLink
                            key={item.path}
                            to={item.path}
                            style={({ isActive }) => ({
                                ...styles.navLink,
                                background: isActive ? '#f1f5f9' : 'transparent',
                                color: isActive ? '#1e293b' : '#64748b',
                                fontWeight: isActive ? '600' : '400',
                            })}
                        >
                            {item.icon}
                            <span>{item.label}</span>
                        </NavLink>
                    ))}
                </nav>

                <div style={styles.sidebarFooter}>
                    <button onClick={handleLogout} style={styles.logoutBtn}>
                        <LogOut size={20} />
                        <span>Logout</span>
                    </button>
                </div>
            </aside>

            {/* Main Content */}
            <main style={{
                ...styles.main,
                marginLeft: isSidebarOpen ? '260px' : '0',
            }}>
                {/* Header */}
                <header style={styles.header}>
                    <button
                        onClick={() => setIsSidebarOpen(!isSidebarOpen)}
                        style={styles.menuToggle}
                    >
                        {isSidebarOpen ? <X size={24} /> : <Menu size={24} />}
                    </button>

                    <div style={{ flex: 1 }}></div>

                    <div style={styles.headerActions}>
                        <button style={styles.iconBtn}><Bell size={20} /></button>
                        <button style={styles.iconBtn}><Settings size={20} /></button>
                        <div style={styles.userProfile}>
                            <UserCircle size={28} style={{ color: '#64748b' }} />
                            <div style={styles.userInfo}>
                                <span style={styles.userName}>{admin?.name || 'Admin'}</span>
                                <span style={styles.userRole}>Super Admin</span>
                            </div>
                        </div>
                    </div>
                </header>

                <div style={styles.content}>
                    {children}
                </div>
            </main>
        </div>
    );
};

const styles = {
    container: {
        display: 'flex',
        height: '100vh',
        background: '#f8fafc',
        fontFamily: "'Inter', sans-serif",
    },
    sidebar: {
        position: 'fixed',
        height: '100vh',
        background: 'white',
        borderRight: '1px solid #e2e8f0',
        display: 'flex',
        flexDirection: 'column',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        zIndex: 100,
        overflow: 'hidden',
    },
    logoContainer: {
        padding: '2rem 1.5rem',
    },
    logoText: {
        margin: 0,
        fontSize: '1.25rem',
        fontWeight: '800',
        color: '#1e293b',
        letterSpacing: '-0.5px',
    },
    nav: {
        padding: '1rem',
        display: 'flex',
        flexDirection: 'column',
        gap: '0.5rem',
        flex: 1,
    },
    navLink: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.75rem',
        padding: '0.875rem 1rem',
        textDecoration: 'none',
        borderRadius: '12px',
        transition: 'all 0.2s ease',
    },
    sidebarFooter: {
        padding: '1.5rem',
        borderTop: '1px solid #f1f5f9',
    },
    logoutBtn: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.75rem',
        width: '100%',
        padding: '0.875rem 1rem',
        background: 'transparent',
        border: 'none',
        color: '#ef4444',
        fontWeight: '600',
        cursor: 'pointer',
        borderRadius: '12px',
        textAlign: 'left',
        transition: 'all 0.2s ease',
    },
    main: {
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        height: '100vh',
        transition: 'margin 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
    },
    header: {
        height: '70px',
        background: 'white',
        borderBottom: '1px solid #e2e8f0',
        display: 'flex',
        alignItems: 'center',
        padding: '0 1.5rem',
        position: 'sticky',
        top: 0,
        zIndex: 90,
    },
    menuToggle: {
        background: 'transparent',
        border: 'none',
        color: '#64748b',
        cursor: 'pointer',
        padding: '0.5rem',
        borderRadius: '8px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
    },
    headerActions: {
        display: 'flex',
        alignItems: 'center',
        gap: '1rem',
    },
    iconBtn: {
        background: '#f1f5f9',
        border: 'none',
        color: '#64748b',
        width: '40px',
        height: '40px',
        borderRadius: '10px',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
    },
    userProfile: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.75rem',
        padding: '0.4rem 0.75rem',
        borderRadius: '12px',
        background: '#f8fafc',
    },
    userInfo: {
        display: 'flex',
        flexDirection: 'column',
    },
    userName: {
        fontSize: '0.875rem',
        fontWeight: '600',
        color: '#1e293b',
    },
    userRole: {
        fontSize: '0.75rem',
        color: '#64748b',
    },
    content: {
        padding: '2rem',
        overflowY: 'auto',
        flex: 1,
    }
};

export default Layout;
