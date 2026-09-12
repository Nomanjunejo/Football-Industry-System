import React from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export function RequireStaff({ children, roles }) {
  const { user, isStaff } = useAuth()
  if (!user || !isStaff) return <Navigate to="/admin/login" replace />
  if (roles && !roles.includes(user.role)) {
    return (
      <div className="max-w-2xl mx-auto py-16 text-center">
        <h2 className="text-xl font-semibold text-red-600">Access denied</h2>
        <p className="text-gray-500 mt-2">Your role ({user.role}) does not have permission to view this page.</p>
      </div>
    )
  }
  return children
}

export function RequireCustomer({ children }) {
  const { user, isCustomer } = useAuth()
  if (!user || !isCustomer) return <Navigate to="/customer/login" replace />
  return children
}
