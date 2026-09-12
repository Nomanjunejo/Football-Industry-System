import React, { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

export default function AdminLogin() {
  const [email, setEmail] = useState('admin@footballindustry.local')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')

  const { loginAsEmployee } = useAuth()
  const navigate = useNavigate()

  const submit = async (e) => {
    e.preventDefault()
    setError('')

    try {
      const data = await loginAsEmployee(email, password)

      // Redirect according to employee role
      switch (data.role) {
        case 'Admin':
          navigate('/admin/dashboard')
          break

        case 'ProductionManager':
          navigate('/admin/production')
          break

        case 'WarehouseStaff':
          navigate('/admin/inventory')
          break

        case 'ExportOfficer':
          navigate('/admin/export-orders')
          break

        case 'QualityInspector':
          navigate('/admin/quality-control')
          break

        default:
          setError('Your account has an unrecognized role.')
      }
    } catch (err) {
      setError(
        err.response?.data?.detail ||
        'Login failed. Check your credentials.'
      )
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-pitch-900">
      <form
        onSubmit={submit}
        className="bg-white rounded-lg shadow-lg p-8 w-full max-w-sm"
      >
        <h1 className="text-xl font-bold mb-1">
          ⚽ Staff Login
        </h1>

        <p className="text-sm text-gray-500 mb-6">
          Admin, Production, Warehouse, Export &amp; QC accounts
        </p>

        <label className="text-sm font-medium">
          Email
        </label>

        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="border rounded-md px-3 py-2 w-full mt-1 mb-4 text-sm"
          required
        />

        <label className="text-sm font-medium">
          Password
        </label>

        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="border rounded-md px-3 py-2 w-full mt-1 mb-4 text-sm"
          required
        />

        {error && (
          <p className="text-sm text-red-600 mb-3">
            {error}
          </p>
        )}

        <button
          className="bg-pitch-700 text-white w-full py-2.5 rounded-md font-medium hover:bg-pitch-800"
        >
          Log In
        </button>

        <p className="text-xs text-gray-400 mt-4">
          Demo password for all seeded staff accounts:{' '}
          <code>Passw0rd!</code>
        </p>

        <Link
          to="/"
          className="block text-center text-sm text-pitch-700 mt-4"
        >
          ← Back to site
        </Link>
      </form>
    </div>
  )
}