import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { getCompanyPerformance } from '../../services/resourceService'

export default function Ranking() {
  const [performance, setPerformance] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getCompanyPerformance().then(setPerformance).finally(() => setLoading(false))
  }, [])

  // Simple, transparent scoring: revenue and export-market breadth are
  // combined into a single 0-100 "System Calculated Industry Score" purely
  // from this database's own data -- never presented as an official ranking.
  const maxRevenue = Math.max(1, ...performance.map((p) => Number(p.TotalExportRevenue || 0)))
  const maxMarkets = Math.max(1, ...performance.map((p) => Number(p.DistinctExportMarkets || 0)))

  const ranked = performance
    .map((p) => ({
      ...p,
      score: (
        (Number(p.TotalExportRevenue || 0) / maxRevenue) * 70 +
        (Number(p.DistinctExportMarkets || 0) / maxMarkets) * 30
      ).toFixed(1),
    }))
    .sort((a, b) => b.score - a.score)

  return (
    <div>
      <h1 className="text-2xl font-bold mb-1">Manufacturer Ranking</h1>
      <p className="text-sm text-gray-500 mb-1">
        <strong>System Calculated Industry Score</strong> — derived from export revenue and market reach
        within this database only. This is <em>not</em> an official FIFA or industry ranking.
      </p>

      {loading ? (
        <p className="text-gray-400 mt-4">Loading...</p>
      ) : (
        <div className="bg-white rounded-lg shadow mt-6 overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3">#</th>
                <th className="text-left px-4 py-3">Company</th>
                <th className="text-left px-4 py-3">Export Revenue</th>
                <th className="text-left px-4 py-3">Export Markets</th>
                <th className="text-left px-4 py-3">System Score</th>
              </tr>
            </thead>
            <tbody>
              {ranked.map((r, idx) => (
                <tr key={r.ManufacturerID} className="border-b last:border-0">
                  <td className="px-4 py-3 font-medium">{idx + 1}</td>
                  <td className="px-4 py-3">
                    <Link to={`/companies/${r.ManufacturerID}`} className="text-pitch-700 hover:underline">
                      {r.CompanyName}
                    </Link>
                  </td>
                  <td className="px-4 py-3">${Number(r.TotalExportRevenue).toLocaleString()}</td>
                  <td className="px-4 py-3">{r.DistinctExportMarkets}</td>
                  <td className="px-4 py-3 font-semibold text-pitch-700">{r.score}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
