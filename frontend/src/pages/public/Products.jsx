import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { getProducts } from '../../services/resourceService'
import { useCart } from '../../context/CartContext'

const CATEGORIES = ['', 'Match', 'Training', 'Futsal', 'Beach', 'Youth', 'Promotional', 'Custom']

export default function Products() {
  const [products, setProducts] = useState([])
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState('')
  const [sortBy, setSortBy] = useState('name')
  const [loading, setLoading] = useState(true)
  const { addToCart } = useCart()

  useEffect(() => {
    setLoading(true)
    const params = {}
    if (search) params.search = search
    if (category) params.category = category
    getProducts(params).then(setProducts).finally(() => setLoading(false))
  }, [search, category])

  const sorted = [...products].sort((a, b) => {
    if (sortBy === 'price_asc') return a.Price - b.Price
    if (sortBy === 'price_desc') return b.Price - a.Price
    if (sortBy === 'rating') return b.AverageRating - a.AverageRating
    return a.ProductName.localeCompare(b.ProductName)
  })

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Football Products</h1>

      <div className="flex flex-col md:flex-row gap-3 mb-6">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search products..."
          className="border rounded-md px-3 py-2 text-sm flex-1"
        />
        <select value={category} onChange={(e) => setCategory(e.target.value)} className="border rounded-md px-3 py-2 text-sm">
          {CATEGORIES.map((c) => <option key={c} value={c}>{c || 'All Categories'}</option>)}
        </select>
        <select value={sortBy} onChange={(e) => setSortBy(e.target.value)} className="border rounded-md px-3 py-2 text-sm">
          <option value="name">Sort: Name</option>
          <option value="price_asc">Price: Low to High</option>
          <option value="price_desc">Price: High to Low</option>
          <option value="rating">Highest Rated</option>
        </select>
      </div>

      {loading ? (
        <p className="text-gray-400">Loading products...</p>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-5">
          {sorted.map((p) => (
            <div key={p.ProductID} className="bg-white rounded-lg shadow p-4 flex flex-col">
              <Link to={`/products/${p.ProductID}`}>
                <div className="text-5xl mb-2 text-center">⚽</div>
                <p className="font-medium text-sm">{p.ProductName}</p>
                <p className="text-xs text-gray-400">{p.Category} · Size {p.SizeNumber}</p>
                <p className="text-xs text-yellow-500 mt-1">{'★'.repeat(Math.round(p.AverageRating))}{'☆'.repeat(5 - Math.round(p.AverageRating))}</p>
              </Link>
              <div className="mt-auto pt-3 flex items-center justify-between">
                <span className="text-pitch-700 font-semibold">${Number(p.Price).toFixed(2)}</span>
                <button
                  onClick={() => addToCart(p, 1)}
                  className="text-xs bg-pitch-700 text-white px-3 py-1.5 rounded-md hover:bg-pitch-800"
                >
                  Add to Cart
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
