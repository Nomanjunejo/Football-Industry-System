import React from 'react'
import { Link, NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useCart } from '../context/CartContext'

const linkClass = ({ isActive }) =>
  `px-3 py-2 rounded-md text-sm font-medium ${isActive ? 'bg-pitch-700 text-white' : 'text-gray-700 hover:bg-pitch-50'}`

export default function Navbar() {
  const { user, isCustomer, logout } = useAuth()
  const { items } = useCart()

  return (
    <nav className="bg-white shadow sticky top-0 z-40">
      <div className="max-w-7xl mx-auto px-4 flex items-center justify-between h-16">
        <Link to="/" className="text-xl font-bold text-pitch-700">
          ⚽ Football Industry System
        </Link>
        <div className="hidden md:flex gap-1">
          <NavLink to="/" end className={linkClass}>Home</NavLink>
          <NavLink to="/companies" className={linkClass}>Companies</NavLink>
          <NavLink to="/products" className={linkClass}>Products</NavLink>
          <NavLink to="/compare" className={linkClass}>Compare</NavLink>
          <NavLink to="/ranking" className={linkClass}>Ranking</NavLink>
          <NavLink to="/about" className={linkClass}>About</NavLink>
        </div>
        <div className="flex items-center gap-3">
          <Link to="/cart" className="relative text-gray-700 hover:text-pitch-700">
            🛒 Cart
            {items.length > 0 && (
              <span className="absolute -top-2 -right-3 bg-pitch-700 text-white text-xs rounded-full px-1.5">
                {items.length}
              </span>
            )}
          </Link>
          {user ? (
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-600">Hi, {user.fullName}</span>
              {isCustomer ? (
                <Link to="/my-orders" className="text-sm text-pitch-700 font-medium">My Orders</Link>
              ) : (
                <Link to="/admin/dashboard" className="text-sm text-pitch-700 font-medium">Dashboard</Link>
              )}
              <button onClick={logout} className="text-sm text-gray-500 hover:text-red-600">Logout</button>
            </div>
          ) : (
            <div className="flex gap-2">
              <Link to="/customer/login" className="text-sm text-gray-700">Customer Login</Link>
              <Link to="/admin/login" className="text-sm bg-pitch-700 text-white px-3 py-1.5 rounded-md">Staff Login</Link>
            </div>
          )}
        </div>
      </div>
    </nav>
  )
}
