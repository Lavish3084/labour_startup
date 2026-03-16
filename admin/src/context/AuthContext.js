import React, { createContext, useState, useContext, useEffect } from 'react';
import { authService } from '../services/api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [admin, setAdmin] = useState(null);
    const [token, setToken] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const storedToken = localStorage.getItem('adminToken');
        const user = localStorage.getItem('adminUser');
        if (storedToken && user) {
            setToken(storedToken);
            setAdmin(JSON.parse(user));
        }
        setLoading(false);
    }, []);

    const login = async (email, password) => {
        try {
            const data = await authService.login(email, password);
            if (data.role !== 'admin') {
                throw new Error('Access denied. Not an admin.');
            }
            localStorage.setItem('adminToken', data.token);
            localStorage.setItem('adminUser', JSON.stringify(data));
            setToken(data.token);
            setAdmin(data);
            return true;
        } catch (err) {
            console.error('Login failed:', err);
            throw err;
        }
    };

    const logout = () => {
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminUser');
        setToken(null);
        setAdmin(null);
    };

    return (
        <AuthContext.Provider value={{ admin, token, login, logout, loading }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
