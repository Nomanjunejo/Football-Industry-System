import React, { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { getProduct, getProductReviews, getProductCertifications } from '../../services/resourceService'
import { useCart } from '../../context/CartContext'
import { useAuth } from '../../context/AuthContext'
import { leaveReview } from '../../services/resourceService'

export default function ProductDetails() {
  const { id } = useParams()
  const [product, setProduct] = useState(null)
  const [reviews, setReviews] = useState([])
  const [certifications, setCertifications] = useState([])
  const [quantity, setQuantity] = useState(1)
  const [reviewText, setReviewText] = useState('')
  const [reviewRating, setReviewRating] = useState(5)
  const [reviewMsg, setReviewMsg] = useState('')
  const { addToCart } = useCart()
  const { isCustomer } = useAuth()

  const load = () => {
    Promise.all([getProduct(id), getProductReviews(id), getProductCertifications(id)]).then(
      ([p, r, c]) => {
        setProduct(p)
        setReviews(r)
        setCertifications(c)
      },
    )
  }

  useEffect(load, [id])

  const submitReview = async (e) => {
    e.preventDefault()
    setReviewMsg('')
    try {
      await leaveReview({ ProductID: Number(id), Rating: reviewRating, Comment: reviewText })
      setReviewText('')
      setReviewMsg('Thanks for your review!')
      load()
    } catch (err) {
      setReviewMsg(err.response?.data?.detail || 'Could not submit review.')
    }
  }

  if (!product) return <p className="text-gray-400">Loading...</p>

  return (
    <div>
      <Link to="/products" className="text-sm text-pitch-700">← Back to Products</Link>

      <div className="bg-white rounded-lg shadow p-6 mt-4 grid md:grid-cols-2 gap-8">
        {/* <div className="text-9xl text-center py-12">⚽</div> */}
        {/* PRODUCT IMAGE: ImageURL database se aa raha hai */}
<div className="text-center py-12">
  <img
    src={product.ImageURL}
    alt={product.ProductName}
    className="w-full h-80 object-contain rounded-lg"
  />
</div>
        <div>
          <h1 className="text-2xl font-bold">{product.ProductName}</h1>
          <p className="text-gray-500">{product.Category} · Size {product.SizeNumber} · {product.Material}</p>
          <p className="text-yellow-500 mt-2">
            {'★'.repeat(Math.round(product.AverageRating))}{'☆'.repeat(5 - Math.round(product.AverageRating))}
            <span className="text-gray-400 text-sm ml-2">({reviews.length} reviews)</span>
          </p>
          <p className="text-3xl font-bold text-pitch-700 mt-4">${Number(product.Price).toFixed(2)}</p>
          <p className="text-gray-600 mt-4">{product.Description}</p>
          {product.ConstructionMethod && (
            <p className="text-sm text-gray-500 mt-2">Construction: {product.ConstructionMethod}</p>
          )}

          <div className="flex items-center gap-3 mt-6">
            <input
              type="number"
              min="1"
              value={quantity}
              onChange={(e) => setQuantity(Math.max(1, Number(e.target.value)))}
              className="border rounded-md px-3 py-2 w-20 text-sm"
            />
            <button
              onClick={() => addToCart(product, quantity)}
              className="bg-pitch-700 text-white px-5 py-2.5 rounded-md hover:bg-pitch-800"
            >
              Add to Cart
            </button>
          </div>

          {certifications.length > 0 && (
            <div className="mt-6">
              <p className="text-sm font-medium mb-2">Certifications</p>
              <div className="flex flex-wrap gap-2">
                {certifications.map((c) => (
                  <span key={c.CertificationID} className="text-xs bg-pitch-50 text-pitch-700 px-2 py-1 rounded-full">
                    {c.CertificationType} ({c.Status})
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="mt-8">
        <h2 className="text-xl font-semibold mb-4">Customer Reviews</h2>
        <div className="space-y-3 mb-6">
          {reviews.length === 0 && <p className="text-gray-400 text-sm">No reviews yet.</p>}
          {reviews.map((r) => (
            <div key={r.ReviewID} className="bg-white rounded-lg shadow p-4">
              <p className="text-yellow-500 text-sm">{'★'.repeat(r.Rating)}{'☆'.repeat(5 - r.Rating)}</p>
              <p className="text-sm text-gray-700 mt-1">{r.Comment}</p>
            </div>
          ))}
        </div>

        {isCustomer ? (
          <form onSubmit={submitReview} className="bg-white rounded-lg shadow p-4 space-y-3 max-w-lg">
            <p className="font-medium text-sm">Leave a review</p>
            <select value={reviewRating} onChange={(e) => setReviewRating(Number(e.target.value))} className="border rounded-md px-3 py-2 text-sm">
              {[5, 4, 3, 2, 1].map((n) => <option key={n} value={n}>{n} stars</option>)}
            </select>
            <textarea
              value={reviewText}
              onChange={(e) => setReviewText(e.target.value)}
              placeholder="Your thoughts on this football..."
              className="border rounded-md px-3 py-2 text-sm w-full"
              rows={3}
            />
            <button className="bg-pitch-700 text-white px-4 py-2 rounded-md text-sm">Submit Review</button>
            {reviewMsg && <p className="text-sm text-gray-600">{reviewMsg}</p>}
          </form>
        ) : (
          <p className="text-sm text-gray-500">
            <Link to="/customer/login" className="text-pitch-700 underline">Log in</Link> as a customer to leave a review.
          </p>
        )}
      </div>
    </div>
  )
}
