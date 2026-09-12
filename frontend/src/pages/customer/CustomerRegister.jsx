import React, { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { customerRegister } from '../../services/authService'
import { useAuth } from '../../context/AuthContext'

export default function CustomerRegister() {
  const [form, setForm] = useState({ full_name: '', email: '', password: '', phone: '', country: '', city: '' })
  const [error, setError] = useState('')
  const { loginAsCustomer } = useAuth()
  const navigate = useNavigate()

  const update = (field) => (e) => setForm({ ...form, [field]: e.target.value })

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await customerRegister(form)
      await loginAsCustomer(form.email, form.password)
      navigate('/products')
    } catch (err) {
      setError(err.response?.data?.detail || 'Registration failed.')
    }
  }

  return (
    <div className="max-w-md mx-auto py-12">
      <form onSubmit={submit} className="bg-white rounded-lg shadow-lg p-8 space-y-3">
        <h1 className="text-xl font-bold mb-2">Create Customer Account</h1>

        <Field label="Full Name" value={form.full_name} onChange={update('full_name')} required />
        <Field label="Email" type="email" value={form.email} onChange={update('email')} required />
        <Field label="Password" type="password" value={form.password} onChange={update('password')} required minLength={8} />
        <Field label="Phone" value={form.phone} onChange={update('phone')} />
        <div className="grid grid-cols-2 gap-3">
          <Field label="Country" value={form.country} onChange={update('country')} />
          <Field label="City" value={form.city} onChange={update('city')} />
        </div>

        {error && <p className="text-sm text-red-600">{error}</p>}

        <button className="bg-pitch-700 text-white w-full py-2.5 rounded-md font-medium hover:bg-pitch-800 mt-2">
          Create Account
        </button>

        <p className="text-sm text-gray-500 text-center">
          Already have an account? <Link to="/customer/login" className="text-pitch-700 font-medium">Log in</Link>
        </p>
      </form>
    </div>
  )
}

function Field({ label, ...props }) {
  return (
    <div>
      <label className="text-sm font-medium">{label}</label>
      <input {...props} className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
    </div>
  )
}
