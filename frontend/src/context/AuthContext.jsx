import React, { createContext, useContext, useState } from 'react'
import * as authService from '../services/authService'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const token = localStorage.getItem('token')
    if (!token) return null
    return {
      token,
      role: localStorage.getItem('role'),
      fullName: localStorage.getItem('full_name'),
      userId: localStorage.getItem('user_id'),
    }
  })

  const loginAsEmployee = async (email, password) => {
    const data = await authService.employeeLogin(email, password)
    authService.storeSession(data)
    setUser({ token: data.access_token, role: data.role, fullName: data.full_name, userId: data.user_id })
    return data
  }

  const loginAsCustomer = async (email, password) => {
    const data = await authService.customerLogin(email, password)
    authService.storeSession(data)
    setUser({ token: data.access_token, role: data.role, fullName: data.full_name, userId: data.user_id })
    return data
  }

  const logout = () => {
    authService.clearSession()
    setUser(null)
  }

  const isStaff = user && user.role !== 'Customer'
  const isCustomer = user && user.role === 'Customer'

  return (
    <AuthContext.Provider value={{ user, loginAsEmployee, loginAsCustomer, logout, isStaff, isCustomer }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
