import React, { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import {
    Plus,
    Pencil,
    Trash2,
    Save,
    X,
    HelpCircle,
    Search,
    CheckSquare,
    Square
} from 'lucide-react';

const Faqs = () => {
    const [faqs, setFaqs] = useState([]);
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingFaq, setEditingFaq] = useState(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [formData, setFormData] = useState({
        question: '',
        answer: '',
        categories: [] // Array of category names
    });

    useEffect(() => {
        fetchInitialData();
    }, []);

    const fetchInitialData = async () => {
        try {
            setLoading(true);
            const [faqsData, categoriesData] = await Promise.all([
                adminService.getFaqs(),
                adminService.getCategories()
            ]);
            setFaqs(faqsData);
            setCategories(categoriesData);
        } catch (err) {
            console.error('Failed to fetch initial data:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenModal = (faq = null) => {
        if (faq) {
            setEditingFaq(faq);
            setFormData({
                question: faq.question,
                answer: faq.answer,
                categories: faq.categories || []
            });
        } else {
            setEditingFaq(null);
            setFormData({
                question: '',
                answer: '',
                categories: []
            });
        }
        setIsModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        if (formData.categories.length === 0) {
            alert('Please select at least one category for this FAQ.');
            return;
        }

        try {
            if (editingFaq) {
                await adminService.updateFaq(editingFaq._id, formData);
            } else {
                await adminService.createFaq(formData);
            }
            setIsModalOpen(false);
            fetchInitialData();
        } catch (err) {
            alert('Failed to save FAQ');
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this FAQ?')) {
            try {
                await adminService.deleteFaq(id);
                fetchInitialData();
            } catch (err) {
                const message = err.response?.data?.msg || 'Failed to delete FAQ';
                alert(message);
            }
        }
    };

    const handleCategoryToggle = (categoryName) => {
        const currentSelected = [...formData.categories];
        const index = currentSelected.indexOf(categoryName);
        if (index > -1) {
            currentSelected.splice(index, 1);
        } else {
            currentSelected.push(categoryName);
        }
        setFormData({ ...formData, categories: currentSelected });
    };

    const filteredFaqs = faqs.filter(faq => 
        faq.question.toLowerCase().includes(searchQuery.toLowerCase()) ||
        faq.answer.toLowerCase().includes(searchQuery.toLowerCase()) ||
        faq.categories.some(cat => cat.toLowerCase().includes(searchQuery.toLowerCase()))
    );

    if (loading) return <div style={styles.loading}>Loading FAQs...</div>;

    return (
        <div style={styles.container}>
            <header style={styles.header}>
                <div style={styles.titleArea}>
                    <h1 style={styles.title}>Frequently Asked Questions</h1>
                    <p style={styles.subtitle}>Manage standard FAQs, assign them to categories, and keep customer support updated.</p>
                </div>
                <button style={styles.addBtn} onClick={() => handleOpenModal()}>
                    <Plus size={20} />
                    <span>Add FAQ</span>
                </button>
            </header>

            <div style={styles.filterBar}>
                <div style={styles.searchWrapper}>
                    <Search size={18} style={styles.searchIcon} />
                    <input 
                        type="text" 
                        placeholder="Search FAQs by question, answer, or category..." 
                        style={styles.searchInput}
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </div>
            </div>

            <div style={styles.grid}>
                {filteredFaqs.length === 0 ? (
                    <div style={styles.emptyState}>
                        <HelpCircle size={48} color="#94a3b8" />
                        <p style={styles.emptyText}>No FAQs found. Click "Add FAQ" to get started.</p>
                    </div>
                ) : (
                    filteredFaqs.map((faq) => (
                        <div key={faq._id} style={styles.card}>
                            <div style={styles.cardHeader}>
                                <div style={styles.iconBox}>
                                    <HelpCircle size={24} color="#3b82f6" />
                                </div>
                                <div style={styles.cardActions}>
                                    <button style={styles.actionBtn} onClick={() => handleOpenModal(faq)}>
                                        <Pencil size={16} />
                                    </button>
                                    <button style={{ ...styles.actionBtn, color: '#ef4444' }} onClick={() => handleDelete(faq._id)}>
                                        <Trash2 size={16} />
                                    </button>
                                </div>
                            </div>

                            <h3 style={styles.cardName}>{faq.question}</h3>
                            <p style={styles.cardDesc}>{faq.answer}</p>

                            <div style={styles.categoryContainer}>
                                <span style={styles.categoryLabel}>Categories ({faq.categories?.length || 0}):</span>
                                <div style={styles.tagRow}>
                                    {faq.categories && faq.categories.length > 0 ? (
                                        faq.categories.map(cat => (
                                            <span key={cat} style={styles.tag}>{cat}</span>
                                        ))
                                    ) : (
                                        <span style={{ ...styles.tag, background: '#fee2e2', color: '#ef4444' }}>None</span>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))
                )}
            </div>

            {/* Modal */}
            {isModalOpen && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modal}>
                        <div style={styles.modalHeader}>
                            <h2 style={styles.modalTitle}>{editingFaq ? 'Edit FAQ' : 'New FAQ'}</h2>
                            <button style={styles.closeBtn} onClick={() => setIsModalOpen(false)}>
                                <X size={20} />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} style={styles.form}>
                            <div style={styles.field}>
                                <label style={styles.label}>Question</label>
                                <input
                                    style={styles.input}
                                    value={formData.question}
                                    onChange={e => setFormData({ ...formData, question: e.target.value })}
                                    placeholder="e.g. How long does the cleaning service take?"
                                    required
                                />
                            </div>
                            <div style={styles.field}>
                                <label style={styles.label}>Answer</label>
                                <textarea
                                    style={styles.textarea}
                                    value={formData.answer}
                                    onChange={e => setFormData({ ...formData, answer: e.target.value })}
                                    placeholder="e.g. A standard service takes 2-4 hours, depending on the house size..."
                                    required
                                />
                            </div>

                            <div style={styles.field}>
                                <label style={styles.label}>Show in Categories (Select all that apply)</label>
                                <div style={styles.checkboxGrid}>
                                    {categories.length === 0 ? (
                                        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>No categories created yet. Please create a category first.</p>
                                    ) : (
                                        categories.map(cat => {
                                            const isSelected = formData.categories.includes(cat.name);
                                            return (
                                                <div 
                                                    key={cat._id} 
                                                    onClick={() => handleCategoryToggle(cat.name)}
                                                    style={{
                                                        ...styles.checkboxItem,
                                                        borderColor: isSelected ? '#3b82f6' : '#e2e8f0',
                                                        background: isSelected ? '#f0fdf4' : 'transparent',
                                                    }}
                                                >
                                                    {isSelected ? (
                                                        <CheckSquare size={20} color="#16a34a" />
                                                    ) : (
                                                        <Square size={20} color="#64748b" />
                                                    )}
                                                    <span style={styles.checkboxName}>{cat.name}</span>
                                                </div>
                                            );
                                        })
                                    )}
                                </div>
                            </div>

                            <div style={styles.modalFooter}>
                                <button type="button" style={styles.cancelBtn} onClick={() => setIsModalOpen(false)}>Cancel</button>
                                <button type="submit" style={styles.saveBtn}>
                                    <Save size={18} style={{ marginRight: 8 }} />
                                    Save FAQ
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
        maxWidth: '500px',
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
        gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
        gap: '1.5rem',
    },
    card: {
        background: 'white',
        borderRadius: '20px',
        border: '1px solid #e2e8f0',
        padding: '1.5rem',
        display: 'flex',
        flexDirection: 'column',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05)',
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
        margin: '0 0 0.75rem 0',
        lineHeight: '1.4',
    },
    cardDesc: {
        fontSize: '0.875rem',
        color: '#64748b',
        lineHeight: '1.6',
        margin: '0 0 1.25rem 0',
        flex: 1,
        whiteSpace: 'pre-wrap',
    },
    categoryContainer: {
        paddingTop: '1rem',
        borderTop: '1px solid #f1f5f9',
        display: 'flex',
        flexDirection: 'column',
        gap: '0.5rem',
    },
    categoryLabel: {
        fontSize: '0.75rem',
        color: '#94a3b8',
        fontWeight: '600',
        textTransform: 'uppercase',
    },
    tagRow: {
        display: 'flex',
        flexWrap: 'wrap',
        gap: '0.4rem',
    },
    tag: {
        fontSize: '0.75rem',
        padding: '0.25rem 0.6rem',
        background: '#f0fdf4',
        color: '#16a34a',
        fontWeight: '600',
        borderRadius: '6px',
        border: '1px solid #dcfce7',
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
        maxWidth: '650px',
        padding: '2rem',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)',
        maxHeight: '90vh',
        overflowY: 'auto',
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
    field: {
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
        minHeight: '120px',
        fontFamily: 'inherit',
        resize: 'vertical',
    },
    checkboxGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))',
        gap: '0.75rem',
        maxHeight: '200px',
        overflowY: 'auto',
        padding: '0.5rem',
        border: '1px solid #e2e8f0',
        borderRadius: '12px',
    },
    checkboxItem: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.75rem',
        padding: '0.6rem 0.875rem',
        borderRadius: '10px',
        border: '1px solid',
        cursor: 'pointer',
        userSelect: 'none',
        transition: 'all 0.15s ease',
    },
    checkboxName: {
        fontSize: '0.875rem',
        fontWeight: '500',
        color: '#1e293b',
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
        fontSize: '1.125rem',
        color: '#64748b',
    },
    emptyState: {
        gridColumn: '1 / -1',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '1rem',
        padding: '4rem 2rem',
        background: 'white',
        borderRadius: '24px',
        border: '1px dashed #cbd5e1',
        textAlign: 'center',
    },
    emptyText: {
        color: '#64748b',
        fontSize: '1rem',
    }
};

export default Faqs;
