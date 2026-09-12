import React, { useEffect, useState } from 'react'
import DataTable from '../../components/DataTable'
import { getSuppliers, createSupplier, getRawMaterials, createRawMaterial } from '../../services/resourceService'

export default function Suppliers() {
  const [suppliers, setSuppliers] = useState([])
  const [materials, setMaterials] = useState([])
  const [tab, setTab] = useState('suppliers')
  const [supForm, setSupForm] = useState({ SupplierName: '', Country: '', City: '', ContactEmail: '', MaterialCategory: '' })
  const [matForm, setMatForm] = useState({ SupplierID: '', MaterialName: '', Unit: 'meter', UnitCost: '', StockQuantity: 0, ReorderLevel: 100 })
  const [error, setError] = useState('')

  const load = () => {
    getSuppliers().then(setSuppliers)
    getRawMaterials().then(setMaterials)
  }
  useEffect(() => { load() }, [])

  const submitSupplier = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await createSupplier(supForm)
      setSupForm({ SupplierName: '', Country: '', City: '', ContactEmail: '', MaterialCategory: '' })
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not save supplier.')
    }
  }

  const submitMaterial = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await createRawMaterial({ ...matForm, SupplierID: Number(matForm.SupplierID), UnitCost: Number(matForm.UnitCost) })
      setMatForm({ SupplierID: '', MaterialName: '', Unit: 'meter', UnitCost: '', StockQuantity: 0, ReorderLevel: 100 })
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not save raw material.')
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Suppliers &amp; Raw Materials</h1>

      <div className="flex gap-2 mb-6">
        <button onClick={() => setTab('suppliers')} className={`px-4 py-2 rounded-md text-sm ${tab === 'suppliers' ? 'bg-pitch-700 text-white' : 'bg-white'}`}>Suppliers</button>
        <button onClick={() => setTab('materials')} className={`px-4 py-2 rounded-md text-sm ${tab === 'materials' ? 'bg-pitch-700 text-white' : 'bg-white'}`}>Raw Materials</button>
      </div>

      {tab === 'suppliers' && (
        <>
          <form onSubmit={submitSupplier} className="bg-white rounded-lg shadow p-5 mb-6 grid grid-cols-1 md:grid-cols-3 gap-3">
            <Input label="Supplier Name" value={supForm.SupplierName} onChange={(v) => setSupForm({ ...supForm, SupplierName: v })} required />
            <Input label="Country" value={supForm.Country} onChange={(v) => setSupForm({ ...supForm, Country: v })} required />
            <Input label="City" value={supForm.City} onChange={(v) => setSupForm({ ...supForm, City: v })} />
            <Input label="Contact Email" type="email" value={supForm.ContactEmail} onChange={(v) => setSupForm({ ...supForm, ContactEmail: v })} />
            <Input label="Material Category" value={supForm.MaterialCategory} onChange={(v) => setSupForm({ ...supForm, MaterialCategory: v })} />
            {error && <p className="text-sm text-red-600 md:col-span-3">{error}</p>}
            <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm w-fit">Add Supplier</button>
          </form>
          <DataTable
            columns={[
              { key: 'SupplierName', label: 'Name' },
              { key: 'Country', label: 'Country' },
              { key: 'City', label: 'City' },
              { key: 'MaterialCategory', label: 'Category' },
              { key: 'Rating', label: 'Rating' },
            ]}
            rows={suppliers}
          />
        </>
      )}

      {tab === 'materials' && (
        <>
          <form onSubmit={submitMaterial} className="bg-white rounded-lg shadow p-5 mb-6 grid grid-cols-1 md:grid-cols-3 gap-3">
            <div>
              <label className="text-sm font-medium">Supplier</label>
              <select value={matForm.SupplierID} onChange={(e) => setMatForm({ ...matForm, SupplierID: e.target.value })} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
                <option value="">Select supplier...</option>
                {suppliers.map((s) => <option key={s.SupplierID} value={s.SupplierID}>{s.SupplierName}</option>)}
              </select>
            </div>
            <Input label="Material Name" value={matForm.MaterialName} onChange={(v) => setMatForm({ ...matForm, MaterialName: v })} required />
            <div>
              <label className="text-sm font-medium">Unit</label>
              <select value={matForm.Unit} onChange={(e) => setMatForm({ ...matForm, Unit: e.target.value })} className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
                {['kg', 'meter', 'piece', 'liter', 'roll'].map((u) => <option key={u}>{u}</option>)}
              </select>
            </div>
            <Input label="Unit Cost" type="number" step="0.01" value={matForm.UnitCost} onChange={(v) => setMatForm({ ...matForm, UnitCost: v })} required />
            <Input label="Stock Quantity" type="number" value={matForm.StockQuantity} onChange={(v) => setMatForm({ ...matForm, StockQuantity: v })} />
            <Input label="Reorder Level" type="number" value={matForm.ReorderLevel} onChange={(v) => setMatForm({ ...matForm, ReorderLevel: v })} />
            {error && <p className="text-sm text-red-600 md:col-span-3">{error}</p>}
            <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm w-fit">Add Raw Material</button>
          </form>
          <DataTable
            columns={[
              { key: 'MaterialName', label: 'Material' },
              { key: 'Unit', label: 'Unit' },
              { key: 'UnitCost', label: 'Unit Cost', render: (r) => `$${Number(r.UnitCost).toFixed(2)}` },
              { key: 'StockQuantity', label: 'Stock' },
              { key: 'ReorderLevel', label: 'Reorder Level' },
            ]}
            rows={materials}
          />
        </>
      )}
    </div>
  )
}

function Input({ label, onChange, ...props }) {
  return (
    <div>
      <label className="text-sm font-medium">{label}</label>
      <input {...props} onChange={(e) => onChange(e.target.value)} className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
    </div>
  )
}
