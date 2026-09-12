import React, { useEffect, useState } from 'react'
import DataTable from '../../components/DataTable'
import Badge from '../../components/Badge'
import {
  getExportOrders, placeExportOrder, updateExportOrderStatus, updateShipment,
  getClients, getProducts,
} from '../../services/resourceService'

const EXPORT_STATUSES = ['Processing', 'Packed', 'Shipped', 'In Transit', 'Customs', 'Delivered', 'Cancelled']
const PAYMENT_STATUSES = ['Pending', 'Paid', 'Failed', 'Refunded']

export default function ExportOrders() {
  const [orders, setOrders] = useState([])
  const [clients, setClients] = useState([])
  const [products, setProducts] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ ClientID: '', DestinationCountry: '', OrderLines: [{ ProductID: '', Quantity: '', UnitPrice: '' }] })
  const [error, setError] = useState('')
  const [clientsError, setClientsError] = useState('')

  const load = () => getExportOrders().then(setOrders)
  useEffect(() => { load() }, [])
  useEffect(() => {
    getClients()
      .then(setClients)
      .catch(err => {
        const msg = err.response?.data?.detail || err.message || 'Failed to load clients'
        setClientsError(msg)
        console.error('Failed to load clients:', err)
      })
    getProducts({ limit: 200 })
      .then(setProducts)
      .catch(err => console.error('Failed to load products:', err))
  }, [])

  const updateLine = (idx, field, value) => {
    const lines = [...form.OrderLines]
    lines[idx] = { ...lines[idx], [field]: value }
    if (field === 'ProductID') {
      const p = products.find((x) => x.ProductID === Number(value))
      if (p) lines[idx].UnitPrice = p.Price
    }
    setForm({ ...form, OrderLines: lines })
  }

  const addLine = () => setForm({ ...form, OrderLines: [...form.OrderLines, { ProductID: '', Quantity: '', UnitPrice: '' }] })
  const removeLine = (idx) => setForm({ ...form, OrderLines: form.OrderLines.filter((_, i) => i !== idx) })

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await placeExportOrder({
        ClientID: Number(form.ClientID),
        DestinationCountry: form.DestinationCountry,
        OrderLines: form.OrderLines.map((l) => ({ ProductID: Number(l.ProductID), Quantity: Number(l.Quantity), UnitPrice: Number(l.UnitPrice) })),
      })
      setForm({ ClientID: '', DestinationCountry: '', OrderLines: [{ ProductID: '', Quantity: '', UnitPrice: '' }] })
      setShowForm(false)
      load()
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not place export order.')
    }
  }

  const changeExportStatus = async (id, ExportStatus) => {
    await updateExportOrderStatus(id, { ExportStatus })
    await updateShipment(id, { ShipmentStatus: ExportStatus })
    load()
  }

  const changePaymentStatus = async (id, PaymentStatus) => {
    await updateExportOrderStatus(id, { PaymentStatus })
    load()
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-2xl font-bold">Export Orders</h1>
        <button onClick={() => setShowForm((s) => !s)} className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm">
          {showForm ? 'Cancel' : '+ Place Export Order'}
        </button>
      </div>

      {clientsError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4 text-red-700">
          <p className="font-medium">Error loading clients:</p>
          <p className="text-sm">{clientsError}</p>
        </div>
      )}

      {showForm && (
        <form onSubmit={submit} className="bg-white rounded-lg shadow p-5 mb-6 space-y-3">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label className="text-sm font-medium">Client</label>
              <select value={form.ClientID} onChange={(e) => {
                const client = clients.find((c) => c.ClientID === Number(e.target.value))
                setForm({ ...form, ClientID: e.target.value, DestinationCountry: client?.Country || '' })
              }} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
                <option value="">Select client...</option>
                {clients.map((c) => <option key={c.ClientID} value={c.ClientID}>{c.CompanyName} ({c.Country})</option>)}
              </select>
            </div>
            <div>
              <label className="text-sm font-medium">Destination Country</label>
              <input value={form.DestinationCountry} onChange={(e) => setForm({ ...form, DestinationCountry: e.target.value })} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
            </div>
          </div>

          <p className="text-sm font-medium mt-3">Order Lines</p>
          {form.OrderLines.map((line, idx) => (
            <div key={idx} className="grid grid-cols-1 md:grid-cols-4 gap-2 items-end">
              <div className="md:col-span-2">
                <select value={line.ProductID} onChange={(e) => updateLine(idx, 'ProductID', e.target.value)} required className="border rounded-md px-3 py-2 w-full text-sm">
                  <option value="">Select product...</option>
                  {products.map((p) => <option key={p.ProductID} value={p.ProductID}>{p.ProductName}</option>)}
                </select>
              </div>
              <input type="number" placeholder="Quantity" value={line.Quantity} onChange={(e) => updateLine(idx, 'Quantity', e.target.value)} required className="border rounded-md px-3 py-2 text-sm" />
              <div className="flex gap-2">
                <input type="number" step="0.01" placeholder="Unit Price" value={line.UnitPrice} onChange={(e) => updateLine(idx, 'UnitPrice', e.target.value)} required className="border rounded-md px-3 py-2 text-sm flex-1" />
                {form.OrderLines.length > 1 && <button type="button" onClick={() => removeLine(idx)} className="text-red-500 text-xs">✕</button>}
              </div>
            </div>
          ))}
          <button type="button" onClick={addLine} className="text-pitch-700 text-sm">+ Add line</button>

          {error && <p className="text-sm text-red-600">{error}</p>}
          <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm">Place Order</button>
        </form>
      )}

      <DataTable
        columns={[
          { key: 'ExportOrderID', label: 'Order #' },
          { key: 'DestinationCountry', label: 'Destination' },
          { key: 'TotalAmount', label: 'Total', render: (r) => `$${Number(r.TotalAmount).toLocaleString()}` },
          { key: 'PaymentStatus', label: 'Payment', render: (r) => (
            <select value={r.PaymentStatus} onChange={(e) => changePaymentStatus(r.ExportOrderID, e.target.value)} className="border-0 bg-transparent text-xs">
              {PAYMENT_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          ) },
          { key: 'ExportStatus', label: 'Export Status', render: (r) => (
            <select value={r.ExportStatus} onChange={(e) => changeExportStatus(r.ExportOrderID, e.target.value)} className="border-0 bg-transparent text-xs">
              {EXPORT_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          ) },
        ]}
        rows={orders}
      />
    </div>
  )
}
