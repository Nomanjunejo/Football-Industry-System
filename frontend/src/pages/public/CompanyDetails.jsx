import React, { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { getManufacturer, getProducts } from '../../services/resourceService'

export default function CompanyDetails() {
  const { id } = useParams()
  const [company, setCompany] = useState(null)
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    Promise.all([getManufacturer(id), getProducts({ manufacturer_id: id })])
      .then(([c, p]) => {
        setCompany(c)
        setProducts(p)
      })
      .finally(() => setLoading(false))
  }, [id])

  if (loading) return <p className="text-gray-400">Loading...</p>
  if (!company) return <p className="text-red-500">Company not found.</p>

  return (
    <div>
      <Link to="/companies" className="text-sm text-pitch-700">← Back to Companies</Link>

      <div className="bg-white rounded-lg shadow p-6 mt-4">
        <div className="flex justify-between items-start flex-wrap gap-2">
          <div>
            <h1 className="text-2xl font-bold">{company.CompanyName}</h1>
            <p className="text-gray-500">{company.City ? `${company.City}, ` : ''}{company.Country}</p>
          </div>
          <span className={`text-xs px-3 py-1 rounded-full ${
            company.DataType === 'Verified' ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700'
          }`}>
            {company.DataType} data
          </span>
        </div>

        {company.Description && <p className="mt-4 text-gray-700">{company.Description}</p>}

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
          <Info label="Company Type" value={company.CompanyType} />
          <Info label="Established" value={company.EstablishedYear} />
          <Info label="Export Markets" value={company.PrimaryExportMarkets} />
          <Info label="Website" value={company.Website ? (
            <a href={company.Website} target="_blank" rel="noreferrer" className="text-pitch-700 underline">{company.Website}</a>
          ) : '—'} />
        </div>

        {company.DataSource && (
          <p className="text-xs text-gray-400 mt-6">
            Data source: {company.DataSource} · Verification status: {company.VerificationStatus}
          </p>
        )}
      </div>

      <h2 className="text-xl font-semibold mt-8 mb-4">Products from {company.CompanyName}</h2>
      {products.length === 0 ? (
        <p className="text-gray-400">No products listed for this manufacturer yet.</p>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {products.map((p) => (
            <Link key={p.ProductID} to={`/products/${p.ProductID}`} className="bg-white rounded-lg shadow p-4 hover:shadow-md">
              <div className="text-4xl mb-2 text-center">⚽</div>
              <p className="font-medium text-sm">{p.ProductName}</p>
              <p className="text-pitch-700 font-semibold mt-1">${Number(p.Price).toFixed(2)}</p>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}

function Info({ label, value }) {
  return (
    <div>
      <p className="text-xs uppercase text-gray-400">{label}</p>
      <p className="text-sm font-medium mt-0.5">{value || '—'}</p>
    </div>
  )
}
