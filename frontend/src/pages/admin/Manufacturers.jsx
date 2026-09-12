import React, { useEffect, useState } from 'react'
import DataTable from '../../components/DataTable'
import Badge from '../../components/Badge'
import { getManufacturers, createManufacturer, deleteManufacturer } from '../../services/resourceService'

const emptyForm = { CompanyName: '', Country: '', City: '', EstablishedYear: '', CompanyType: 'Manufacturer', Description: '' }

export default function Manufacturers() {
  const [rows, setRows] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')

  const load = () => getManufacturers({ limit: 200 }).then(setRows)
  useEffect(() => { load() }, [])

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await createManufacturer({ ...form, EstablishedYear: form.EstablishedYear ? Number(form.EstablishedYear) : null })
      setForm(emptyForm)
      setShowForm(false)
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not save manufacturer.')
    }
  }

  const remove = async (id) => {
    if (!confirm('Deactivate this manufacturer?')) return
    await deleteManufacturer(id)
    load()
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-2xl font-bold">Manufacturers</h1>
        <button onClick={() => setShowForm((s) => !s)} className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm">
          {showForm ? 'Cancel' : '+ Add Manufacturer'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={submit} className="bg-white rounded-lg shadow p-5 mb-6 grid grid-cols-1 md:grid-cols-3 gap-3">
          <Field label="Company Name" value={form.CompanyName} onChange={(v) => setForm({ ...form, CompanyName: v })} required />
          <Field label="Country" value={form.Country} onChange={(v) => setForm({ ...form, Country: v })} required />
          <Field label="City" value={form.City} onChange={(v) => setForm({ ...form, City: v })} />
          <Field label="Established Year" type="number" value={form.EstablishedYear} onChange={(v) => setForm({ ...form, EstablishedYear: v })} />
          <div>
            <label className="text-sm font-medium">Company Type</label>
            <select value={form.CompanyType} onChange={(e) => setForm({ ...form, CompanyType: e.target.value })} className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
              <option>Manufacturer</option>
              <option>Exporter</option>
              <option>Manufacturer & Exporter</option>
              <option>Distributor</option>
            </select>
          </div>
          <div className="md:col-span-3">
            <label className="text-sm font-medium">Description</label>
            <textarea value={form.Description} onChange={(e) => setForm({ ...form, Description: e.target.value })} className="border rounded-md px-3 py-2 w-full mt-1 text-sm" rows={2} />
          </div>
          {error && <p className="text-sm text-red-600 md:col-span-3">{error}</p>}
          <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm md:col-span-3 w-fit">Save</button>
          <p className="text-xs text-gray-400 md:col-span-3">
            New manufacturers created here are marked DataType = "Synthetic" by default (this is a demo entry, not a verified company record).
          </p>
        </form>
      )}

      <DataTable
        columns={[
          { key: 'CompanyName', label: 'Company' },
          { key: 'Country', label: 'Country' },
          { key: 'City', label: 'City' },
          { key: 'CompanyType', label: 'Type' },
          { key: 'DataType', label: 'Data Type', render: (r) => <Badge value={r.DataType} /> },
          { key: 'actions', label: '', render: (r) => (
            <button onClick={() => remove(r.ManufacturerID)} className="text-red-500 text-xs">Deactivate</button>
          ) },
        ]}
        rows={rows}
      />
    </div>
  )
}

function Field({ label, ...props }) {
  return (
    <div>
      <label className="text-sm font-medium">{label}</label>
      <input {...props} onChange={(e) => props.onChange(e.target.value)} className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
    </div>
  )
}
