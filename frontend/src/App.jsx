import React from 'react'
import { Routes, Route } from 'react-router-dom'

import PublicLayout from './layouts/PublicLayout'
import AdminLayout from './layouts/AdminLayout'
import { RequireStaff, RequireCustomer } from './components/ProtectedRoute'

// Public pages
import Home from './pages/public/Home'
import Companies from './pages/public/Companies'
import CompanyDetails from './pages/public/CompanyDetails'
import Products from './pages/public/Products'
import ProductDetails from './pages/public/ProductDetails'
import About from './pages/public/About'
import CompareCompanies from './pages/public/CompareCompanies'
import Ranking from './pages/public/Ranking'

// Auth pages
import AdminLogin from './pages/admin/AdminLogin'
import CustomerLogin from './pages/customer/CustomerLogin'
import CustomerRegister from './pages/customer/CustomerRegister'

// Customer pages
import Cart from './pages/customer/Cart'
import Checkout from './pages/customer/Checkout'
import MyOrders from './pages/customer/MyOrders'

// Admin pages
import Dashboard from './pages/admin/Dashboard'
import Manufacturers from './pages/admin/Manufacturers'
import Suppliers from './pages/admin/Suppliers'
import ProductsAdmin from './pages/admin/ProductsAdmin'
import Production from './pages/admin/Production'
import QualityControl from './pages/admin/QualityControl'
import Warehouses from './pages/admin/Warehouses'
import Clients from './pages/admin/Clients'
import ExportOrders from './pages/admin/ExportOrders'
import Reports from './pages/admin/Reports'

export default function App() {
  return (
    <Routes>
      {/* Public + Customer-facing site */}
      <Route element={<PublicLayout />}>
        <Route path="/" element={<Home />} />
        <Route path="/companies" element={<Companies />} />
        <Route path="/companies/:id" element={<CompanyDetails />} />
        <Route path="/products" element={<Products />} />
        <Route path="/products/:id" element={<ProductDetails />} />
        <Route path="/about" element={<About />} />
        <Route path="/compare" element={<CompareCompanies />} />
        <Route path="/ranking" element={<Ranking />} />

        <Route path="/customer/login" element={<CustomerLogin />} />
        <Route path="/customer/register" element={<CustomerRegister />} />

        <Route path="/cart" element={<Cart />} />
        <Route path="/checkout" element={<Checkout />} />
        <Route path="/my-orders" element={<RequireCustomer><MyOrders /></RequireCustomer>} />
      </Route>

      {/* Staff login (standalone, no navbar) */}
      <Route path="/admin/login" element={<AdminLogin />} />

      {/* Admin panel */}
      <Route path="/admin" element={<RequireStaff><AdminLayout /></RequireStaff>}>
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="manufacturers" element={<Manufacturers />} />
        <Route path="suppliers" element={<Suppliers />} />
        <Route path="products" element={<ProductsAdmin />} />
        <Route path="production" element={<Production />} />
        <Route path="quality-control" element={<QualityControl />} />
        <Route path="warehouses" element={<Warehouses />} />
        <Route path="inventory" element={<Warehouses />} />
        <Route path="clients" element={<Clients />} />
        <Route path="export-orders" element={<ExportOrders />} />
        <Route path="reports" element={<Reports />} />
      </Route>

      <Route path="*" element={<NotFound />} />
    </Routes>
  )
}

function NotFound() {
  return (
    <div className="text-center py-20">
      <h1 className="text-2xl font-bold">404 — Page Not Found</h1>
    </div>
  )
}
