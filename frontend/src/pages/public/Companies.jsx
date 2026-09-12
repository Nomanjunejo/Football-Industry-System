import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { getManufacturers } from '../../services/resourceService'

export default function Companies() {
  const [manufacturers, setManufacturers] = useState([])
  const [country, setCountry] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    getManufacturers(country ? { country } : {})
      .then(setManufacturers)
      .finally(() => setLoading(false))
  }, [country])

  const countries = ['', 'Pakistan', 'Denmark']

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold">Football Companies</h1>
          <p className="text-gray-500 text-sm mt-1">
            Manufacturers and exporters, focused on Sialkot, Pakistan — the world's largest hand-stitched
            football manufacturing cluster.
          </p>
        </div>
        <select
          value={country}
          onChange={(e) => setCountry(e.target.value)}
          className="border rounded-md px-3 py-2 text-sm"
        >
          {countries.map((c) => (
            <option key={c} value={c}>{c || 'All Countries'}</option>
          ))}
        </select>
      </div>

      {loading ? (
        <p className="text-gray-400">Loading companies...</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {manufacturers.map((m) => (
            <Link
              key={m.ManufacturerID}
              to={`/companies/${m.ManufacturerID}`}
              className="bg-white rounded-lg shadow p-5 hover:shadow-lg transition"
            >
              <div className="flex justify-between items-start">
                <h3 className="font-semibold text-lg">{m.CompanyName}</h3>
                <span className={`text-xs px-2 py-0.5 rounded-full whitespace-nowrap ${
                  m.DataType === 'Verified' ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700'
                }`}>
                  {m.DataType}
                </span>
              </div>
              <p className="text-sm text-gray-500 mt-1">{m.City ? `${m.City}, ` : ''}{m.Country}</p>
              {m.EstablishedYear && <p className="text-xs text-gray-400 mt-1">Established {m.EstablishedYear}</p>}
              {m.Description && <p className="text-sm text-gray-600 mt-3 line-clamp-3">{m.Description}</p>}
              <div className="mt-3 flex flex-wrap gap-1">
                {m.CompanyType && (
                  <span className="text-xs bg-pitch-50 text-pitch-700 px-2 py-0.5 rounded-full">{m.CompanyType}</span>
                )}
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
