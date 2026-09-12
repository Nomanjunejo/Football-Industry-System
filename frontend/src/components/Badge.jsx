import React from 'react'

const STYLES = {
  Verified: 'bg-green-100 text-green-800',
  Estimated: 'bg-yellow-100 text-yellow-800',
  Synthetic: 'bg-gray-200 text-gray-700',
  Completed: 'bg-green-100 text-green-800',
  Delivered: 'bg-green-100 text-green-800',
  Paid: 'bg-green-100 text-green-800',
  PASS: 'bg-green-100 text-green-800',
  Available: 'bg-green-100 text-green-800',
  Planned: 'bg-blue-100 text-blue-800',
  Processing: 'bg-blue-100 text-blue-800',
  'In Production': 'bg-blue-100 text-blue-800',
  Shipped: 'bg-blue-100 text-blue-800',
  'In Transit': 'bg-blue-100 text-blue-800',
  Packed: 'bg-blue-100 text-blue-800',
  Customs: 'bg-indigo-100 text-indigo-800',
  Pending: 'bg-yellow-100 text-yellow-800',
  'Low Stock': 'bg-yellow-100 text-yellow-800',
  Failed: 'bg-red-100 text-red-800',
  FAIL: 'bg-red-100 text-red-800',
  Cancelled: 'bg-red-100 text-red-800',
  Refunded: 'bg-red-100 text-red-800',
  'Out of Stock': 'bg-red-100 text-red-800',
}

export default function Badge({ value }) {
  const style = STYLES[value] || 'bg-gray-100 text-gray-700'
  return <span className={`inline-block px-2 py-0.5 rounded-full text-xs font-medium ${style}`}>{value}</span>
}
