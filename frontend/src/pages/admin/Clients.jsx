import React, { useEffect, useState } from 'react'
import DataTable from '../../components/DataTable'
import { getClients, createClient } from '../../services/resourceService'

const emptyForm = { CompanyName: '', Country: '', City: '', ContactPerson: '', ContactEmail: '', ContactPhone: '' }

export default function Clients() {
  const [rows, setRows] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')

  const load = () => getClients().then(setRows)
  useEffect(() => { load() }, [])

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await createClient(form)
      setForm(emptyForm)
      setShowForm(false)
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not save client.')
    }
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-2xl font-bold">Buyers / Clients</h1>
        <button onClick={() => setShowForm((s) => !s)} className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm">
          {showForm ? 'Cancel' : '+ Add Client'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={submit} className="bg-white rounded-lg shadow p-5 mb-6 grid grid-cols-1 md:grid-cols-3 gap-3">
          <Field label="Company Name" value={form.CompanyName} onChange={(v) => setForm({ ...form, CompanyName: v })} required />
          <Field label="Country" value={form.Country} onChange={(v) => setForm({ ...form, Country: v })} required />
          <Field label="City" value={form.City} onChange={(v) => setForm({ ...form, City: v })} />
          <Field label="Contact Person" value={form.ContactPerson} onChange={(v) => setForm({ ...form, ContactPerson: v })} />
          <Field label="Contact Email" type="email" value={form.ContactEmail} onChange={(v) => setForm({ ...form, ContactEmail: v })} required />
          <Field label="Contact Phone" value={form.ContactPhone} onChange={(v) => setForm({ ...form, ContactPhone: v })} />
          {error && <p className="text-sm text-red-600 md:col-span-3">{error}</p>}
          <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm md:col-span-3 w-fit">Save Client</button>
        </form>
      )}

      <DataTable
        columns={[
          { key: 'CompanyName', label: 'Company' },
          { key: 'Country', label: 'Country' },
          { key: 'City', label: 'City' },
          { key: 'ContactPerson', label: 'Contact' },
          { key: 'ContactEmail', label: 'Email' },
        ]}
        rows={rows}
      />
    </div>
  )
}

function Field({ label, onChange, ...props }) {
  return (
    <div>
      <label className="text-sm font-medium">{label}</label>
      <input {...props} onChange={(e) => onChange(e.target.value)} className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
    </div>
  )
}
