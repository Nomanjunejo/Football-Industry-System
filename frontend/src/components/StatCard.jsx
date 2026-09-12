import React from 'react'

// NOTE: Tailwind scans source files for literal class name strings, so
// color classes must be spelled out in full here rather than built with
// template-string interpolation (e.g. `text-${accent}-700`), or Tailwind's
// JIT compiler will not generate the CSS for them.
export default function StatCard({ label, value, sublabel }) {
  return (
    <div className="bg-white rounded-lg shadow p-5">
      <p className="text-xs uppercase tracking-wide text-gray-500 font-medium">{label}</p>
      <p className="text-3xl font-bold mt-1 text-pitch-700">{value}</p>
      {sublabel && <p className="text-xs text-gray-400 mt-1">{sublabel}</p>}
    </div>
  )
}
