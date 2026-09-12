import React, { useEffect, useState } from 'react'
import {
  LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'
import StatCard from '../../components/StatCard'
import {
  getDashboard, getMonthlyExportTrend, getRevenueByCountry, getProductSalesPerformance,
} from '../../services/resourceService'

export default function Dashboard() {
  const [summary, setSummary] = useState(null)
  const [trend, setTrend] = useState([])
  const [byCountry, setByCountry] = useState([])
  const [topProducts, setTopProducts] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([getDashboard(), getMonthlyExportTrend(), getRevenueByCountry(), getProductSalesPerformance()])
      .then(([s, t, c, p]) => {
        setSummary(s)
        setTrend(t.map((row) => ({ month: row.MonthStart?.slice(0, 7), revenue: Number(row.Revenue) })))
        setByCountry(c.slice(0, 8).map((row) => ({ country: row.DestinationCountry, revenue: Number(row.TotalRevenue) })))
        setTopProducts(
          [...p]
            .sort((a, b) => Number(b.ExportRevenue || 0) - Number(a.ExportRevenue || 0))
            .slice(0, 8)
            .map((row) => ({ name: row.ProductName, revenue: Number(row.ExportRevenue || 0) })),
        )
      })
      .finally(() => setLoading(false))
  }, [])

  if (loading || !summary) return <p className="text-gray-400">Loading dashboard...</p>

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <StatCard label="Manufacturers" value={summary.total_manufacturers} />
        <StatCard label="Products" value={summary.total_products} />
        <StatCard label="Production Units" value={summary.total_production_units.toLocaleString()} />
        <StatCard label="Inventory Units" value={summary.total_inventory_units.toLocaleString()} />
        <StatCard label="Export Orders" value={summary.total_export_orders} />
        <StatCard label="Export Revenue" value={`$${Number(summary.total_export_revenue).toLocaleString()}`} />
        <StatCard label="Customers" value={summary.total_customers} />
        <StatCard label="Buyers" value={summary.total_buyers} />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
        <StatCard label="Top Export Country" value={summary.top_export_country || '—'} />
        <StatCard label="Best Selling Product" value={summary.best_selling_product || '—'} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-4">
          <p className="font-medium mb-3">Monthly Export Revenue Trend</p>
          <ResponsiveContainer width="100%" height={260}>
            <LineChart data={trend}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Line type="monotone" dataKey="revenue" stroke="#16803c" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white rounded-lg shadow p-4">
          <p className="font-medium mb-3">Export Revenue by Country</p>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={byCountry}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="country" tick={{ fontSize: 10 }} interval={0} angle={-20} textAnchor="end" height={60} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="revenue" fill="#16803c" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white rounded-lg shadow p-4 lg:col-span-2">
          <p className="font-medium mb-3">Top Products by Export Revenue</p>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={topProducts} layout="vertical" margin={{ left: 40 }}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis type="number" tick={{ fontSize: 11 }} />
              <YAxis type="category" dataKey="name" tick={{ fontSize: 11 }} width={160} />
              <Tooltip />
              <Bar dataKey="revenue" fill="#0d4f26" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}
