import React from 'react'

export default function About() {
  return (
    <div className="max-w-3xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">About This Project</h1>
      <p className="text-gray-700 mb-4">
        This site is the frontend for a university <strong>Database Management Systems</strong> lab project:
        the Football Manufacturing, Export, Industry Intelligence &amp; E-Commerce Management System. A
        Microsoft SQL Server database is the core of the system — every page here is rendered from live
        queries, views, and stored procedures rather than hardcoded content.
      </p>

      <h2 className="text-lg font-semibold mt-6 mb-2">Real vs. Estimated vs. Synthetic Data</h2>
      <p className="text-gray-700 mb-3">
        Company listings are labelled with a data-quality badge so nothing here is mistaken for verified
        market intelligence:
      </p>
      <ul className="space-y-2 text-sm">
        <li><span className="bg-green-100 text-green-800 px-2 py-0.5 rounded-full text-xs mr-2">Verified</span>
          Identity facts (name, city, country, company type) for real, publicly documented football
          manufacturers, primarily from Sialkot, Pakistan.</li>
        <li><span className="bg-yellow-100 text-yellow-800 px-2 py-0.5 rounded-full text-xs mr-2">Estimated</span>
          Plausible values used where exact public figures were not available.</li>
        <li><span className="bg-gray-200 text-gray-700 px-2 py-0.5 rounded-full text-xs mr-2">Synthetic</span>
          Demo data (production batches, orders, customers, reviews) generated purely to exercise the
          database — not real business activity.</li>
      </ul>

      <h2 className="text-lg font-semibold mt-6 mb-2">Manufacturer Ranking</h2>
      <p className="text-gray-700">
        The score shown on the Ranking page is a <strong>System Calculated Industry Score</strong> derived
        from export performance, product ratings, and product range within this database. It is not an
        official FIFA ranking or any third-party industry ranking.
      </p>
    </div>
  )
}
