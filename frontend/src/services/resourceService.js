import api from './api'

// ---------- Manufacturers / Company Directory ----------
export const getManufacturers = (params = {}) => api.get('/api/manufacturers', { params }).then((r) => r.data)
export const getManufacturer = (id) => api.get(`/api/manufacturers/${id}`).then((r) => r.data)
export const createManufacturer = (payload) => api.post('/api/manufacturers', payload).then((r) => r.data)
export const updateManufacturer = (id, payload) => api.put(`/api/manufacturers/${id}`, payload).then((r) => r.data)
export const deleteManufacturer = (id) => api.delete(`/api/manufacturers/${id}`).then((r) => r.data)

// ---------- Products ----------
export const getProducts = (params = {}) => api.get('/api/products', { params }).then((r) => r.data)
export const getProduct = (id) => api.get(`/api/products/${id}`).then((r) => r.data)
export const getProductReviews = (id) => api.get(`/api/products/${id}/reviews`).then((r) => r.data)
export const getProductCertifications = (id) => api.get(`/api/products/${id}/certifications`).then((r) => r.data)
export const createProduct = (payload) => api.post('/api/products', payload).then((r) => r.data)
export const updateProduct = (id, payload) => api.put(`/api/products/${id}`, payload).then((r) => r.data)
export const deleteProduct = (id) => api.delete(`/api/products/${id}`).then((r) => r.data)

// ---------- Suppliers / Raw Materials ----------
export const getSuppliers = () => api.get('/api/suppliers').then((r) => r.data)
export const createSupplier = (payload) => api.post('/api/suppliers', payload).then((r) => r.data)
export const getRawMaterials = () => api.get('/api/suppliers/raw-materials').then((r) => r.data)
export const createRawMaterial = (payload) => api.post('/api/suppliers/raw-materials', payload).then((r) => r.data)

// ---------- Production / QC ----------
export const getBatches = (params = {}) => api.get('/api/production/batches', { params }).then((r) => r.data)
export const createBatch = (payload) => api.post('/api/production/batches', payload).then((r) => r.data)
export const updateBatchStatus = (id, payload) => api.patch(`/api/production/batches/${id}/status`, payload).then((r) => r.data)
export const createInspection = (payload) => api.post('/api/production/inspections', payload).then((r) => r.data)

// ---------- Warehouses / Inventory ----------
export const getWarehouses = () => api.get('/api/warehouses').then((r) => r.data)
export const createWarehouse = (payload) => api.post('/api/warehouses', payload).then((r) => r.data)
export const getInventory = (params = {}) => api.get('/api/warehouses/inventory', { params }).then((r) => r.data)
export const adjustInventory = (payload) => api.post('/api/warehouses/inventory/adjust', payload).then((r) => r.data)

// ---------- Export ----------
export const getClients = () => api.get('/api/export/clients').then((r) => r.data)
export const createClient = (payload) => api.post('/api/export/clients', payload).then((r) => r.data)
export const getExportOrders = (params = {}) => api.get('/api/export/orders', { params }).then((r) => r.data)
export const getExportOrder = (id) => api.get(`/api/export/orders/${id}`).then((r) => r.data)
export const placeExportOrder = (payload) => api.post('/api/export/orders', payload).then((r) => r.data)
export const updateExportOrderStatus = (id, payload) => api.patch(`/api/export/orders/${id}/status`, payload).then((r) => r.data)
export const updateShipment = (id, payload) => api.patch(`/api/export/orders/${id}/shipment`, payload).then((r) => r.data)

// ---------- Marketplace (customer) ----------
export const checkout = (payload) => api.post('/api/marketplace/checkout', payload).then((r) => r.data)
export const getMyOrders = () => api.get('/api/marketplace/orders').then((r) => r.data)
export const leaveReview = (payload) => api.post('/api/marketplace/reviews', payload).then((r) => r.data)

// ---------- Analytics ----------
export const getDashboard = () => api.get('/api/analytics/dashboard').then((r) => r.data)
export const getRevenueByCountry = () => api.get('/api/analytics/export-revenue-by-country').then((r) => r.data)
export const getLowStock = () => api.get('/api/analytics/low-stock').then((r) => r.data)
export const getProductionSummary = () => api.get('/api/analytics/production-summary').then((r) => r.data)
export const getCompanyPerformance = () => api.get('/api/analytics/company-performance').then((r) => r.data)
export const getProductSalesPerformance = () => api.get('/api/analytics/product-sales-performance').then((r) => r.data)
export const getTopExportMarkets = () => api.get('/api/analytics/top-export-markets').then((r) => r.data)
export const getMonthlyExportTrend = () => api.get('/api/analytics/monthly-export-trend').then((r) => r.data)
