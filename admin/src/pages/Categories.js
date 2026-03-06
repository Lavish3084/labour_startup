import React, { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import {
    Plus,
    Pencil,
    Trash2,
    Save,
    X,
    LayoutGrid,
    Search
} from 'lucide-react';

const Categories = () => {
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingCategory, setEditingCategory] = useState(null);
    const [formData, setFormData] = useState({
        name: '',
        iconName: '',
        description: '',
        hourlyRate: '',
        dailyRate: '',
        supportedModes: ['Hourly', 'Daily']
    });

    useEffect(() => {
        fetchCategories();
    }, []);

    const fetchCategories = async () => {
        try {
            const data = await adminService.getCategories();
            setCategories(data);
        } catch (err) {
            console.error('Failed to fetch categories:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenModal = (category = null) => {
        if (category) {
            setEditingCategory(category);
            setFormData({
                name: category.name,
                iconName: category.iconName,
                description: category.description,
                hourlyRate: category.hourlyRate,
                dailyRate: category.dailyRate,
                supportedModes: category.supportedModes
            });
        } else {
            setEditingCategory(null);
            setFormData({
                name: '',
                iconName: '',
                description: '',
                hourlyRate: '',
                dailyRate: '',
                supportedModes: ['Hourly', 'Daily']
            });
        }
        setIsModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingCategory) {
                await adminService.updateCategory(editingCategory._id, formData);
            } else {
                await adminService.createCategory(formData);
            }
            setIsModalOpen(false);
            fetchCategories();
        } catch (err) {
            alert('Failed to save category');
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this category?')) {
            try {
                await adminService.deleteCategory(id);
                fetchCategories();
            } catch (err) {
                alert('Failed to delete category');
            }
        }
    };

    if (loading) return <div style={styles.loading}>Loading Categories...</div>;

    return (
        <div style={styles.container}>
            <header style={styles.header}>
                <div style={styles.titleArea}>
                    <h1 style={styles.title}>Categories</h1>
                    <p style={styles.subtitle}>Manage service sectors and their pricing models.</p>
                </div>
                <button style={styles.addBtn} onClick={() => handleOpenModal()}>
                    <Plus size={20} />
                    <span>Add Category</span>
                </button>
            </header>

            <div style={styles.filterBar}>
                <div style={styles.searchWrapper}>
                    <Search size={18} style={styles.searchIcon} />
                    <input type="text" placeholder="Search categories..." style={styles.searchInput} />
                </div>
            </div>

            <div style={styles.grid}>
                {categories.map((category) => (
                    <div key={category._id} style={styles.card}>
                        <div style={styles.cardHeader}>
                            <div style={styles.iconBox}>
                                <LayoutGrid size={24} color="#3b82f6" />
                            </div>
                            <div style={styles.cardActions}>
                                <button style={styles.actionBtn} onClick={() => handleOpenModal(category)}>
                                    <Pencil size={16} />
                                </button>
                                <button style={{ ...styles.actionBtn, color: '#ef4444' }} onClick={() => handleDelete(category._id)}>
                                    <Trash2 size={16} />
                                </button>
                            </div>
                        </div>
                        <h3 style={styles.cardName}>{category.name}</h3>
                        <p style={styles.cardDesc}>{category.description}</p>

                        <div style={styles.priceRow}>
                            <div style={styles.priceItem}>
                                <span style={styles.priceLabel}>Hourly</span>
                                <span style={styles.priceValue}>₹{category.hourlyRate}</span>
                            </div>
                            <div style={styles.priceItem}>
                                <span style={styles.priceLabel}>Daily</span>
                                <span style={styles.priceValue}>₹{category.dailyRate}</span>
                            </div>
                        </div>

                        <div style={styles.tagRow}>
                            {category.supportedModes.map(mode => (
                                <span key={mode} style={styles.tag}>{mode}</span>
                            ))}
                        </div>
                    </div>
                ))}
            </div>

            {/* Modal */}
            {isModalOpen && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modal}>
                        <div style={styles.modalHeader}>
                            <h2 style={styles.modalTitle}>{editingCategory ? 'Edit Category' : 'New Category'}</h2>
                            <button style={styles.closeBtn} onClick={() => setIsModalOpen(false)}>
                                <X size={20} />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} style={styles.form}>
                            <div style={styles.formRow}>
                                <div style={styles.field}>
                                    <label style={styles.label}>Name</label>
                                    <input
                                        style={styles.input}
                                        value={formData.name}
                                        onChange={e => setFormData({ ...formData, name: e.target.value })}
                                        required
                                    />
                                </div>
                                <div style={styles.field}>
                                    <label style={styles.label}>Icon Name (Material)</label>
                                    <input
                                        style={styles.input}
                                        value={formData.iconName}
                                        onChange={e => setFormData({ ...formData, iconName: e.target.value })}
                                        required
                                    />
                                </div>
                            </div>
                            <div style={styles.field}>
                                <label style={styles.label}>Description</label>
                                <textarea
                                    style={styles.textarea}
                                    value={formData.description}
                                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                                />
                            </div>
                            <div style={styles.formRow}>
                                <div style={styles.field}>
                                    <label style={styles.label}>Hourly Rate (₹)</label>
                                    <input
                                        type="number"
                                        style={styles.input}
                                        value={formData.hourlyRate}
                                        onChange={e => setFormData({ ...formData, hourlyRate: e.target.value })}
                                        required
                                    />
                                </div>
                                <div style={styles.field}>
                                    <label style={styles.label}>Daily Rate (₹)</label>
                                    <input
                                        type="number"
                                        style={styles.input}
                                        value={formData.dailyRate}
                                        onChange={e => setFormData({ ...formData, dailyRate: e.target.value })}
                                        required
                                    />
                                </div>
                            </div>
                            <div style={styles.modalFooter}>
                                <button type="button" style={styles.cancelBtn} onClick={() => setIsModalOpen(false)}>Cancel</button>
                                <button type="submit" style={styles.saveBtn}>
                                    <Save size={18} style={{ marginRight: 8 }} />
                                    Save Category
                                </button>
                            </div>
                        </form>
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
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
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
    addBtn: {
        background: '#1e293b',
        color: 'white',
        border: 'none',
        padding: '0.75rem 1.25rem',
        borderRadius: '12px',
        fontWeight: '600',
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        cursor: 'pointer',
        boxShadow: '0 4px 12px rgba(30, 41, 59, 0.2)',
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
    grid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
        gap: '1.5rem',
    },
    card: {
        background: 'white',
        borderRadius: '20px',
        border: '1px solid #e2e8f0',
        padding: '1.5rem',
        display: 'flex',
        flexDirection: 'column',
    },
    cardHeader: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '1rem',
    },
    iconBox: {
        width: '44px',
        height: '44px',
        background: '#eff6ff',
        borderRadius: '12px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
    },
    cardActions: {
        display: 'flex',
        gap: '0.5rem',
    },
    actionBtn: {
        background: '#f8fafc',
        border: 'none',
        color: '#64748b',
        padding: '0.4rem',
        borderRadius: '8px',
        cursor: 'pointer',
    },
    cardName: {
        fontSize: '1.125rem',
        fontWeight: '700',
        color: '#1e293b',
        margin: '0 0 0.5rem 0',
    },
    cardDesc: {
        fontSize: '0.875rem',
        color: '#64748b',
        lineHeight: '1.5',
        margin: '0 0 1.25rem 0',
        flex: 1,
    },
    priceRow: {
        display: 'flex',
        gap: '1.5rem',
        padding: '1rem 0',
        borderTop: '1px solid #f1f5f9',
        borderBottom: '1px solid #f1f5f9',
        marginBottom: '1rem',
    },
    priceItem: {
        display: 'flex',
        flexDirection: 'column',
    },
    priceLabel: {
        fontSize: '0.75rem',
        color: '#94a3b8',
        fontWeight: '600',
        textTransform: 'uppercase',
    },
    priceValue: {
        fontSize: '1.125rem',
        fontWeight: '700',
        color: '#1e293b',
    },
    tagRow: {
        display: 'flex',
        gap: '0.5rem',
    },
    tag: {
        fontSize: '0.75rem',
        padding: '0.2rem 0.6rem',
        background: '#f1f5f9',
        color: '#64748b',
        fontWeight: '600',
        borderRadius: '6px',
    },
    modalOverlay: {
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(30, 41, 59, 0.4)',
        backdropFilter: 'blur(4px)',
        zIndex: 1000,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
    },
    modal: {
        background: 'white',
        borderRadius: '24px',
        width: '100%',
        maxWidth: '600px',
        padding: '2rem',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)',
    },
    modalHeader: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '2rem',
    },
    modalTitle: {
        margin: 0,
        fontSize: '1.5rem',
        fontWeight: '800',
    },
    closeBtn: {
        background: '#f1f5f9',
        border: 'none',
        borderRadius: '50%',
        width: '36px',
        height: '36px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
    },
    form: {
        display: 'flex',
        flexDirection: 'column',
        gap: '1.5rem',
    },
    formRow: {
        display: 'flex',
        gap: '1.5rem',
    },
    field: {
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        gap: '0.5rem',
    },
    label: {
        fontSize: '0.875rem',
        fontWeight: '600',
        color: '#1e293b',
    },
    input: {
        padding: '0.75rem 1rem',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        outline: 'none',
        fontSize: '1rem',
    },
    textarea: {
        padding: '0.75rem 1rem',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        outline: 'none',
        fontSize: '1rem',
        minHeight: '100px',
        fontFamily: 'inherit',
    },
    modalFooter: {
        display: 'flex',
        justifyContent: 'flex-end',
        gap: '1rem',
        marginTop: '1rem',
    },
    cancelBtn: {
        padding: '0.75rem 1.5rem',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        background: 'white',
        fontWeight: '600',
        cursor: 'pointer',
    },
    saveBtn: {
        padding: '0.75rem 1.5rem',
        borderRadius: '12px',
        border: 'none',
        background: '#1e293b',
        color: 'white',
        fontWeight: '600',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
    },
    loading: {
        display: 'flex',
        height: '100%',
        alignItems: 'center',
        justifyContent: 'center',
    }
};

export default Categories;
