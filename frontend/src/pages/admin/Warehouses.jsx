import React, { useEffect, useState } from 'react'
import DataTable from '../../components/DataTable'
import Badge from '../../components/Badge'
import { getWarehouses, createWarehouse, getInventory, adjustInventory, getProducts } from '../../services/resourceService'

export default function Warehouses() {
  const [warehouses, setWarehouses] = useState([])
  const [inventory, setInventory] = useState([])
  const [products, setProducts] = useState([])
  const [tab, setTab] = useState('inventory')
  const [whForm, setWhForm] = useState({ WarehouseName: '', Location: '', Capacity: '' })
  const [adjForm, setAdjForm] = useState({ ProductID: '', WarehouseID: '', QuantityDelta: '' })
  const [error, setError] = useState('')
  const [lowStockOnly, setLowStockOnly] = useState(false)

  const load = () => {
    getWarehouses().then(setWarehouses)
    getInventory(lowStockOnly ? { low_stock_only: true } : {}).then(setInventory)
  }
  useEffect(() => { load() }, [lowStockOnly])
  useEffect(() => { getProducts({ limit: 200 }).then(setProducts) }, [])

  const submitWarehouse = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await createWarehouse({ ...whForm, Capacity: Number(whForm.Capacity) })
      setWhForm({ WarehouseName: '', Location: '', Capacity: '' })
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not save warehouse.')
    }
  }

  const submitAdjustment = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await adjustInventory({
        ProductID: Number(adjForm.ProductID),
        WarehouseID: Number(adjForm.WarehouseID),
        QuantityDelta: Number(adjForm.QuantityDelta),
      })
      setAdjForm({ ProductID: '', WarehouseID: '', QuantityDelta: '' })
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not adjust inventory.')
    }
  }

  const productName = (id) => products.find((p) => p.ProductID === id)?.ProductName || `#${id}`
  const warehouseName = (id) => warehouses.find((w) => w.WarehouseID === id)?.WarehouseName || `#${id}`

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Warehouses &amp; Inventory</h1>

      <div className="flex gap-2 mb-6">
        <button onClick={() => setTab('inventory')} className={`px-4 py-2 rounded-md text-sm ${tab === 'inventory' ? 'bg-pitch-700 text-white' : 'bg-white'}`}>Inventory</button>
        <button onClick={() => setTab('warehouses')} className={`px-4 py-2 rounded-md text-sm ${tab === 'warehouses' ? 'bg-pitch-700 text-white' : 'bg-white'}`}>Warehouses</button>
      </div>

      {tab === 'inventory' && (
        <>
          <form onSubmit={submitAdjustment} className="bg-white rounded-lg shadow p-5 mb-4 grid grid-cols-1 md:grid-cols-4 gap-3">
            <div>
              <label className="text-sm font-medium">Product</label>
              <select value={adjForm.ProductID} onChange={(e) => setAdjForm({ ...adjForm, ProductID: e.target.value })} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
                <option value="">Select product...</option>
                {products.map((p) => <option key={p.ProductID} value={p.ProductID}>{p.ProductName}</option>)}
              </select>
            </div>
            <div>
              <label className="text-sm font-medium">Warehouse</label>
              <select value={adjForm.WarehouseID} onChange={(e) => setAdjForm({ ...adjForm, WarehouseID: e.target.value })} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
                <option value="">Select warehouse...</option>
                {warehouses.map((w) => <option key={w.WarehouseID} value={w.WarehouseID}>{w.WarehouseName}</option>)}
              </select>
            </div>
            <div>
              <label className="text-sm font-medium">Quantity Delta (+/-)</label>
              <input type="number" value={adjForm.QuantityDelta} onChange={(e) => setAdjForm({ ...adjForm, QuantityDelta: e.target.value })} required placeholder="e.g. 100 or -50" className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
            </div>
            <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm self-end h-fit">Adjust Stock</button>
            {error && <p className="text-sm text-red-600 md:col-span-4">{error}</p>}
          </form>

          <label className="flex items-center gap-2 text-sm mb-3">
            <input type="checkbox" checked={lowStockOnly} onChange={(e) => setLowStockOnly(e.target.checked)} />
            Show low-stock / out-of-stock only (vw_LowStockProducts)
          </label>

          <DataTable
            columns={[
              { key: 'ProductID', label: 'Product', render: (r) => productName(r.ProductID) },
              { key: 'WarehouseID', label: 'Warehouse', render: (r) => warehouseName(r.WarehouseID) },
              { key: 'Quantity', label: 'Quantity' },
              { key: 'ReorderLevel', label: 'Reorder Level' },
              { key: 'StockStatus', label: 'Status', render: (r) => <Badge value={r.StockStatus} /> },
            ]}
            rows={inventory}
          />
        </>
      )}

      {tab === 'warehouses' && (
        <>
          <form onSubmit={submitWarehouse} className="bg-white rounded-lg shadow p-5 mb-6 grid grid-cols-1 md:grid-cols-3 gap-3">
            <Field label="Warehouse Name" value={whForm.WarehouseName} onChange={(v) => setWhForm({ ...whForm, WarehouseName: v })} required />
            <Field label="Location" value={whForm.Location} onChange={(v) => setWhForm({ ...whForm, Location: v })} required />
            <Field label="Capacity" type="number" value={whForm.Capacity} onChange={(v) => setWhForm({ ...whForm, Capacity: v })} required />
            {error && <p className="text-sm text-red-600 md:col-span-3">{error}</p>}
            <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm w-fit">Add Warehouse</button>
          </form>
          <DataTable
            columns={[
              { key: 'WarehouseName', label: 'Name' },
              { key: 'Location', label: 'Location' },
              { key: 'Capacity', label: 'Capacity' },
            ]}
            rows={warehouses}
          />
        </>
      )}
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
