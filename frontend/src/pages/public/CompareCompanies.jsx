import React, { useEffect, useState } from 'react'
import { getCompanyPerformance, getManufacturers } from '../../services/resourceService'

export default function CompareCompanies() {
  const [manufacturers, setManufacturers] = useState([])
  const [performance, setPerformance] = useState([])
  const [selected, setSelected] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([getManufacturers({ limit: 100 }), getCompanyPerformance()])
      .then(([m, p]) => {
        setManufacturers(m)
        setPerformance(p)
      })
      .finally(() => setLoading(false))
  }, [])

  const toggleSelect = (id) => {
    setSelected((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : prev.length < 3 ? [...prev, id] : prev,
    )
  }

  const rows = selected.map((id) => {
    const m = manufacturers.find((x) => x.ManufacturerID === id)
    const perf = performance.find((x) => x.ManufacturerID === id)
    return { m, perf }
  })

  return (
    <div>
      <h1 className="text-2xl font-bold mb-2">Compare Companies</h1>
      <p className="text-gray-500 text-sm mb-6">Select up to 3 companies to compare export performance side by side.</p>

      {loading ? (
        <p className="text-gray-400">Loading...</p>
      ) : (
        <>
          <div className="flex flex-wrap gap-2 mb-6">
            {manufacturers.map((m) => (
              <button
                key={m.ManufacturerID}
                onClick={() => toggleSelect(m.ManufacturerID)}
                className={`text-sm px-3 py-1.5 rounded-full border ${
                  selected.includes(m.ManufacturerID)
                    ? 'bg-pitch-700 text-white border-pitch-700'
                    : 'bg-white text-gray-700 border-gray-300'
                }`}
              >
                {m.CompanyName}
              </button>
            ))}
          </div>

          {rows.length > 0 && (
            <div className="bg-white rounded-lg shadow overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead className="bg-gray-50 border-b">
                  <tr>
                    <th className="text-left px-4 py-3">Metric</th>
                    {rows.map(({ m }) => (
                      <th key={m.ManufacturerID} className="text-left px-4 py-3">{m.CompanyName}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  <MetricRow label="Country" rows={rows} render={({ m }) => m.Country} />
                  <MetricRow label="Company Type" render={({ m }) => m.CompanyType || '—'} rows={rows} />
                  <MetricRow label="Total Export Orders" render={({ perf }) => perf?.TotalExportOrders ?? 0} rows={rows} />
                  <MetricRow label="Total Export Revenue" render={({ perf }) => `$${Number(perf?.TotalExportRevenue ?? 0).toLocaleString()}`} rows={rows} />
                  <MetricRow label="Units Exported" render={({ perf }) => perf?.TotalUnitsExported ?? 0} rows={rows} />
                  <MetricRow label="Distinct Export Markets" render={({ perf }) => perf?.DistinctExportMarkets ?? 0} rows={rows} />
                  <MetricRow label="Data Type" render={({ m }) => m.DataType} rows={rows} />
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  )
}

function MetricRow({ label, rows, render }) {
  return (
    <tr className="border-b last:border-0">
      <td className="px-4 py-3 font-medium text-gray-600">{label}</td>
      {rows.map((row) => (
        <td key={row.m.ManufacturerID} className="px-4 py-3">{render(row)}</td>
      ))}
    </tr>
  )
}
