import React from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useCart } from '../../context/CartContext'

export default function Cart() {
  const { items, removeFromCart, updateQuantity, total } = useCart()
  const navigate = useNavigate()

  if (items.length === 0) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-500 mb-4">Your cart is empty.</p>
        <Link to="/products" className="text-pitch-700 font-medium">Browse Products →</Link>
      </div>
    )
  }

  return (
    <div className="max-w-3xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Your Cart</h1>
      <div className="bg-white rounded-lg shadow divide-y">
        {items.map(({ product, quantity }) => (
          <div key={product.ProductID} className="flex items-center justify-between p-4">
            <div>
              <p className="font-medium">{product.ProductName}</p>
              <p className="text-sm text-gray-400">${Number(product.Price).toFixed(2)} each</p>
            </div>
            <div className="flex items-center gap-3">
              <input
                type="number"
                min="1"
                value={quantity}
                onChange={(e) => updateQuantity(product.ProductID, Math.max(1, Number(e.target.value)))}
                className="border rounded-md px-2 py-1 w-16 text-sm"
              />
              <span className="font-medium w-20 text-right">${(product.Price * quantity).toFixed(2)}</span>
              <button onClick={() => removeFromCart(product.ProductID)} className="text-red-500 text-sm">Remove</button>
            </div>
          </div>
        ))}
      </div>

      <div className="flex justify-between items-center mt-6">
        <span className="text-lg font-semibold">Total: ${total.toFixed(2)}</span>
        <button
          onClick={() => navigate('/checkout')}
          className="bg-pitch-700 text-white px-6 py-2.5 rounded-md font-medium hover:bg-pitch-800"
        >
          Proceed to Checkout
        </button>
      </div>
    </div>
  )
}
