import React, { useEffect, useState } from 'react'
import DataTable from '../../components/DataTable'
import Badge from '../../components/Badge'
import { getBatches, createBatch, updateBatchStatus, getProducts, getManufacturers } from '../../services/resourceService'

const emptyForm = { ProductID: '', ManufacturerID: '', Quantity: '', ProductionDate: new Date().toISOString().slice(0, 10) }
const STATUSES = ['Planned', 'In Production', 'Completed', 'Failed', 'Cancelled']

export default function Production() {
  const [batches, setBatches] = useState([])
  const [products, setProducts] = useState([])
  const [manufacturers, setManufacturers] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')
  const [filter, setFilter] = useState('')

  const load = () => getBatches(filter ? { status: filter } : {}).then(setBatches)
  useEffect(() => { load() }, [filter])
  useEffect(() => {
    getProducts({ limit: 200 }).then(setProducts)
    getManufacturers({ limit: 200 }).then(setManufacturers)
  }, [])

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await createBatch({ ...form, ProductID: Number(form.ProductID), ManufacturerID: Number(form.ManufacturerID), Quantity: Number(form.Quantity) })
      setForm(emptyForm)
      setShowForm(false)
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not create batch.')
    }
  }

  const changeStatus = async (batchId, status) => {
    const payload = { Status: status }
    if (status === 'Completed' || status === 'Failed') {
      payload.CompletionDate = new Date().toISOString().slice(0, 10)
    }
    await updateBatchStatus(batchId, payload)
    load()
  }

  const productName = (id) => products.find((p) => p.ProductID === id)?.ProductName || `#${id}`

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-2xl font-bold">Production Batches</h1>
        <button onClick={() => setShowForm((s) => !s)} className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm">
          {showForm ? 'Cancel' : '+ New Batch'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={submit} className="bg-white rounded-lg shadow p-5 mb-6 grid grid-cols-1 md:grid-cols-4 gap-3">
          <div>
            <label className="text-sm font-medium">Product</label>
            <select value={form.ProductID} onChange={(e) => {
              const product = products.find((p) => p.ProductID === Number(e.target.value))
              setForm({ ...form, ProductID: e.target.value, ManufacturerID: product ? String(product.ManufacturerID) : '' })
            }} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
              <option value="">Select product...</option>
              {products.map((p) => <option key={p.ProductID} value={p.ProductID}>{p.ProductName}</option>)}
            </select>
          </div>
          <div>
            <label className="text-sm font-medium">Manufacturer</label>
            <select value={form.ManufacturerID} onChange={(e) => setForm({ ...form, ManufacturerID: e.target.value })} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
              <option value="">Select manufacturer...</option>
              {manufacturers.map((m) => <option key={m.ManufacturerID} value={m.ManufacturerID}>{m.CompanyName}</option>)}
            </select>
          </div>
          <div>
            <label className="text-sm font-medium">Quantity</label>
            <input type="number" value={form.Quantity} onChange={(e) => setForm({ ...form, Quantity: e.target.value })} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
          </div>
          <div>
            <label className="text-sm font-medium">Production Date</label>
            <input type="date" value={form.ProductionDate} onChange={(e) => setForm({ ...form, ProductionDate: e.target.value })} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
          </div>
          {error && <p className="text-sm text-red-600 md:col-span-4">{error}</p>}
          <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm md:col-span-4 w-fit">Create Batch</button>
        </form>
      )}

      <div className="flex gap-2 mb-4">
        {['', ...STATUSES].map((s) => (
          <button key={s} onClick={() => setFilter(s)} className={`text-xs px-3 py-1.5 rounded-full border ${filter === s ? 'bg-pitch-700 text-white border-pitch-700' : 'bg-white text-gray-600'}`}>
            {s || 'All'}
          </button>
        ))}
      </div>

      <DataTable
        columns={[
          { key: 'BatchID', label: 'Batch #' },
          { key: 'ProductID', label: 'Product', render: (r) => productName(r.ProductID) },
          { key: 'Quantity', label: 'Qty' },
          { key: 'ProductionDate', label: 'Production Date' },
          { key: 'Status', label: 'Status', render: (r) => <Badge value={r.Status} /> },
          { key: 'actions', label: 'Move to', render: (r) => (
            <select
              value=""
              onChange={(e) => e.target.value && changeStatus(r.BatchID, e.target.value)}
              className="border rounded-md px-2 py-1 text-xs"
            >
              <option value="">Change status...</option>
              {STATUSES.filter((s) => s !== r.Status).map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          ) },
        ]}
        rows={batches}
      />
    </div>
  )
}
