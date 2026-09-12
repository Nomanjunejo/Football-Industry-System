import React from 'react'
import { Outlet, NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const navItems = [
  { to: '/admin/dashboard', label: '📊 Dashboard' },
  { to: '/admin/manufacturers', label: '🏭 Manufacturers' },
  { to: '/admin/suppliers', label: '📦 Suppliers & Materials' },
  { to: '/admin/products', label: '⚽ Products' },
  { to: '/admin/production', label: '🏗️ Production' },
  { to: '/admin/quality-control', label: '✅ Quality Control' },
  { to: '/admin/warehouses', label: '🏬 Warehouses' },
  { to: '/admin/inventory', label: '📋 Inventory' },
  { to: '/admin/clients', label: '🌍 Buyers / Clients' },
  { to: '/admin/export-orders', label: '🚢 Export Orders' },
  { to: '/admin/reports', label: '📈 Reports & Analytics' },
]

const linkClass = ({ isActive }) =>
  `block px-4 py-2 rounded-md text-sm ${isActive ? 'bg-pitch-700 text-white' : 'text-gray-200 hover:bg-pitch-800'}`

export default function AdminLayout() {
  const { user, logout } = useAuth()

  return (
    <div className="min-h-screen flex">
      <aside className="w-64 bg-pitch-900 flex-shrink-0 flex flex-col">
        <div className="px-4 py-5 text-white font-bold border-b border-pitch-800">
          ⚽ Admin Panel
        </div>
        <nav className="flex-1 px-2 py-4 space-y-1">
          {navItems.map((item) => (
            <NavLink key={item.to} to={item.to} className={linkClass}>{item.label}</NavLink>
          ))}
        </nav>
        <div className="px-4 py-4 border-t border-pitch-800 text-pitch-100 text-sm">
          <div>{user?.fullName}</div>
          <div className="text-pitch-100/60">{user?.role}</div>
          <button onClick={logout} className="mt-2 text-red-300 hover:text-red-100">Logout</button>
        </div>
      </aside>
      <main className="flex-1 bg-gray-100 p-6 overflow-auto">
        <Outlet />
      </main>
    </div>
  )
}
