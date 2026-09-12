import React, { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

export default function CustomerLogin() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const { loginAsCustomer } = useAuth()
  const navigate = useNavigate()

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await loginAsCustomer(email, password)
      navigate('/my-orders')
    } catch (err) {
      setError(err.response?.data?.detail || 'Login failed. Check your credentials.')
    }
  }

  return (
    <div className="max-w-sm mx-auto py-16">
      <form onSubmit={submit} className="bg-white rounded-lg shadow-lg p-8">
        <h1 className="text-xl font-bold mb-6">Customer Login</h1>

        <label className="text-sm font-medium">Email</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="border rounded-md px-3 py-2 w-full mt-1 mb-4 text-sm"
          required
        />

        <label className="text-sm font-medium">Password</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="border rounded-md px-3 py-2 w-full mt-1 mb-4 text-sm"
          required
        />

        {error && <p className="text-sm text-red-600 mb-3">{error}</p>}

        <button className="bg-pitch-700 text-white w-full py-2.5 rounded-md font-medium hover:bg-pitch-800">
          Log In
        </button>

        <p className="text-sm text-gray-500 mt-4 text-center">
          New here? <Link to="/customer/register" className="text-pitch-700 font-medium">Create an account</Link>
        </p>
      </form>
    </div>
  )
}
