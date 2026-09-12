import React, { useEffect, useState } from 'react'
import DataTable from '../../components/DataTable'
import { getProducts, createProduct, deleteProduct, getManufacturers } from '../../services/resourceService'

const emptyForm = { ManufacturerID: '', ProductName: '', Category: 'Match', SizeNumber: 5, Material: '', ConstructionMethod: '', Price: '', Description: '' }
const CATEGORIES = ['Match', 'Training', 'Futsal', 'Beach', 'Youth', 'Promotional', 'Custom']
const CONSTRUCTIONS = ['Hand-Stitched', 'Machine-Stitched', 'Thermal-Bonded', 'Butyl-Bladder']

export default function ProductsAdmin() {
  const [rows, setRows] = useState([])
  const [manufacturers, setManufacturers] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')

  const load = () => getProducts({ limit: 200 }).then(setRows)
  useEffect(() => {
    load()
    getManufacturers({ limit: 200 }).then(setManufacturers)
  }, [])

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await createProduct({
        ...form,
        ManufacturerID: Number(form.ManufacturerID),
        SizeNumber: Number(form.SizeNumber),
        Price: Number(form.Price),
      })
      setForm(emptyForm)
      setShowForm(false)
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not save product.')
    }
  }

  const remove = async (id) => {
    if (!confirm('Deactivate this product?')) return
    await deleteProduct(id)
    load()
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-2xl font-bold">Products</h1>
        <button onClick={() => setShowForm((s) => !s)} className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm">
          {showForm ? 'Cancel' : '+ Add Product'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={submit} className="bg-white rounded-lg shadow p-5 mb-6 grid grid-cols-1 md:grid-cols-3 gap-3">
          <div>
            <label className="text-sm font-medium">Manufacturer</label>
            <select value={form.ManufacturerID} onChange={(e) => setForm({ ...form, ManufacturerID: e.target.value })} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
              <option value="">Select manufacturer...</option>
              {manufacturers.map((m) => <option key={m.ManufacturerID} value={m.ManufacturerID}>{m.CompanyName}</option>)}
            </select>
          </div>
          <Field label="Product Name" value={form.ProductName} onChange={(v) => setForm({ ...form, ProductName: v })} required />
          <div>
            <label className="text-sm font-medium">Category</label>
            <select value={form.Category} onChange={(e) => setForm({ ...form, Category: e.target.value })} className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
              {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
            </select>
          </div>
          <Field label="Size Number (1-5)" type="number" min="1" max="5" value={form.SizeNumber} onChange={(v) => setForm({ ...form, SizeNumber: v })} required />
          <Field label="Material" value={form.Material} onChange={(v) => setForm({ ...form, Material: v })} />
          <div>
            <label className="text-sm font-medium">Construction Method</label>
            <select value={form.ConstructionMethod} onChange={(e) => setForm({ ...form, ConstructionMethod: e.target.value })} className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
              <option value="">—</option>
              {CONSTRUCTIONS.map((c) => <option key={c}>{c}</option>)}
            </select>
          </div>
          <Field label="Price (USD)" type="number" step="0.01" value={form.Price} onChange={(v) => setForm({ ...form, Price: v })} required />
          <div className="md:col-span-3">
            <label className="text-sm font-medium">Description</label>
            <textarea value={form.Description} onChange={(e) => setForm({ ...form, Description: e.target.value })} className="border rounded-md px-3 py-2 w-full mt-1 text-sm" rows={2} />
          </div>
          {error && <p className="text-sm text-red-600 md:col-span-3">{error}</p>}
          <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm md:col-span-3 w-fit">Save Product</button>
        </form>
      )}

      <DataTable
        columns={[
          { key: 'ProductName', label: 'Product' },
          { key: 'Category', label: 'Category' },
          { key: 'SizeNumber', label: 'Size' },
          { key: 'Price', label: 'Price', render: (r) => `$${Number(r.Price).toFixed(2)}` },
          { key: 'AverageRating', label: 'Rating', render: (r) => Number(r.AverageRating).toFixed(1) },
          { key: 'actions', label: '', render: (r) => (
            <button onClick={() => remove(r.ProductID)} className="text-red-500 text-xs">Deactivate</button>
          ) },
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
