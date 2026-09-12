import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { getManufacturers, getProducts } from '../../services/resourceService'

export default function Home() {
  const [manufacturers, setManufacturers] = useState([])
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([getManufacturers({ limit: 6 }), getProducts({ limit: 8 })])
      .then(([m, p]) => {
        setManufacturers(m)
        setProducts(p)
      })
      .finally(() => setLoading(false))
  }, [])

  return (
    <div>
      <section className="bg-pitch-700 text-white rounded-2xl p-10 mb-10">
        <h1 className="text-3xl md:text-4xl font-bold mb-3">
          Pakistan's Football Manufacturing &amp; Export Industry, Digitized
        </h1>
        <p className="text-pitch-50 max-w-2xl mb-6">
          Browse verified manufacturers from Sialkot and beyond, explore football products, compare
          companies, and track industry-wide export performance — all backed by a live relational database.
        </p>
        <div className="flex gap-3">
          <Link to="/companies" className="bg-white text-pitch-700 font-medium px-5 py-2.5 rounded-md">
            Explore Companies
          </Link>
          <Link to="/products" className="border border-white px-5 py-2.5 rounded-md">
            Shop Footballs
          </Link>
        </div>
      </section>

      <section className="mb-10">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Featured Manufacturers</h2>
          <Link to="/companies" className="text-pitch-700 text-sm font-medium">View all →</Link>
        </div>
        {loading ? (
          <p className="text-gray-400">Loading...</p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            {manufacturers.map((m) => (
              <Link
                key={m.ManufacturerID}
                to={`/companies/${m.ManufacturerID}`}
                className="bg-white rounded-lg shadow p-4 hover:shadow-md transition"
              >
                <p className="font-semibold">{m.CompanyName}</p>
                <p className="text-sm text-gray-500">{m.City ? `${m.City}, ` : ''}{m.Country}</p>
                <span className={`inline-block mt-2 text-xs px-2 py-0.5 rounded-full ${
                  m.DataType === 'Verified' ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700'
                }`}>
                  {m.DataType}
                </span>
              </Link>
            ))}
          </div>
        )}
      </section>

      <section>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Popular Products</h2>
          <Link to="/products" className="text-pitch-700 text-sm font-medium">View all →</Link>
        </div>
        {loading ? (
          <p className="text-gray-400">Loading...</p>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {products.map((p) => (
              <Link
                key={p.ProductID}
                to={`/products/${p.ProductID}`}
                className="bg-white rounded-lg shadow p-4 hover:shadow-md transition"
              >
                <div className="text-4xl mb-2 text-center">⚽</div>
                <p className="font-medium text-sm">{p.ProductName}</p>
                <p className="text-pitch-700 font-semibold mt-1">${Number(p.Price).toFixed(2)}</p>
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
