import axios from 'axios';

const API_BASE_URL = 'https://labour-startup.onrender.com/api';

const api = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Request interceptor to add the auth token to every request
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('adminToken');
        if (token) {
            config.headers['x-auth-token'] = token;
        }
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

export const authService = {
    login: async (email, password) => {
        const response = await api.post('/auth/login', { email, password });
        return response.data;
    },
};

export const adminService = {
    getStats: async () => {
        const response = await api.get('/admin/stats');
        return response.data;
    },
    getCategories: async () => {
        const response = await api.get('/admin/categories');
        return response.data;
    },
    createCategory: async (categoryData) => {
        const response = await api.post('/admin/categories', categoryData);
        return response.data;
    },
    updateCategory: async (id, categoryData) => {
        const response = await api.put(`/admin/categories/${id}`, categoryData);
        return response.data;
    },
    deleteCategory: async (id) => {
        const response = await api.delete(`/admin/categories/${id}`);
        return response.data;
    },
};

export default api;
