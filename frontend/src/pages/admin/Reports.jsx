import React, { useEffect, useState } from 'react'
import DataTable from '../../components/DataTable'
import {
  getRevenueByCountry, getProductionSummary, getCompanyPerformance,
  getProductSalesPerformance, getTopExportMarkets, getLowStock,
} from '../../services/resourceService'

const TABS = [
  { key: 'revenue', label: 'Revenue by Country' },
  { key: 'production', label: 'Production Summary' },
  { key: 'company', label: 'Company Performance' },
  { key: 'sales', label: 'Product Sales' },
  { key: 'markets', label: 'Top Export Markets' },
  { key: 'lowstock', label: 'Low Stock' },
]

export default function Reports() {
  const [tab, setTab] = useState('revenue')
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    const fetchers = {
      revenue: getRevenueByCountry,
      production: getProductionSummary,
      company: getCompanyPerformance,
      sales: getProductSalesPerformance,
      markets: getTopExportMarkets,
      lowstock: getLowStock,
    }
    fetchers[tab]().then(setData).finally(() => setLoading(false))
  }, [tab])

  const columnsByTab = {
    revenue: [
      { key: 'DestinationCountry', label: 'Country' },
      { key: 'TotalOrders', label: 'Orders' },
      { key: 'TotalUnitsExported', label: 'Units' },
      { key: 'TotalRevenue', label: 'Revenue', render: (r) => `$${Number(r.TotalRevenue).toLocaleString()}` },
    ],
    production: [
      { key: 'CompanyName', label: 'Manufacturer' },
      { key: 'TotalBatches', label: 'Total Batches' },
      { key: 'CompletedBatches', label: 'Completed' },
      { key: 'FailedBatches', label: 'Failed' },
      { key: 'TotalUnitsProduced', label: 'Units Produced' },
    ],
    company: [
      { key: 'CompanyName', label: 'Company' },
      { key: 'Country', label: 'Country' },
      { key: 'TotalExportOrders', label: 'Orders' },
      { key: 'TotalExportRevenue', label: 'Revenue', render: (r) => `$${Number(r.TotalExportRevenue).toLocaleString()}` },
      { key: 'DistinctExportMarkets', label: 'Markets' },
    ],
    sales: [
      { key: 'ProductName', label: 'Product' },
      { key: 'Category', label: 'Category' },
      { key: 'ExportUnitsSold', label: 'Export Units' },
      { key: 'ExportRevenue', label: 'Export Revenue', render: (r) => `$${Number(r.ExportRevenue || 0).toLocaleString()}` },
      { key: 'MarketplaceUnitsSold', label: 'Marketplace Units' },
      { key: 'MarketplaceRevenue', label: 'Marketplace Revenue', render: (r) => `$${Number(r.MarketplaceRevenue || 0).toLocaleString()}` },
    ],
    markets: [
      { key: 'RevenueRank', label: 'Rank' },
      { key: 'DestinationCountry', label: 'Country' },
      { key: 'TotalRevenue', label: 'Revenue', render: (r) => `$${Number(r.TotalRevenue).toLocaleString()}` },
      { key: 'TotalUnitsExported', label: 'Units' },
      { key: 'TotalOrders', label: 'Orders' },
    ],
    lowstock: [
      { key: 'ProductName', label: 'Product' },
      { key: 'WarehouseName', label: 'Warehouse' },
      { key: 'Quantity', label: 'Quantity' },
      { key: 'ReorderLevel', label: 'Reorder Level' },
      { key: 'StockStatus', label: 'Status' },
    ],
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Reports &amp; Analytics</h1>
      <div className="flex flex-wrap gap-2 mb-6">
        {TABS.map((t) => (
          <button key={t.key} onClick={() => setTab(t.key)} className={`text-sm px-3 py-1.5 rounded-full ${tab === t.key ? 'bg-pitch-700 text-white' : 'bg-white text-gray-600'}`}>
            {t.label}
          </button>
        ))}
      </div>
      {loading ? <p className="text-gray-400">Loading report...</p> : <DataTable columns={columnsByTab[tab]} rows={data} />}
    </div>
  )
}
