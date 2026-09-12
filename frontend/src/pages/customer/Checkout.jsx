import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useCart } from '../../context/CartContext'
import { useAuth } from '../../context/AuthContext'
import { checkout } from '../../services/resourceService'

export default function Checkout() {
  const { items, total, clearCart } = useCart()
  const { user, isCustomer } = useAuth()
  const [address, setAddress] = useState('')
  const [placing, setPlacing] = useState(false)
  const [error, setError] = useState('')
  const navigate = useNavigate()

  if (!isCustomer) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-600 mb-4">Please log in as a customer to check out.</p>
        <button onClick={() => navigate('/customer/login')} className="text-pitch-700 font-medium">Go to Login →</button>
      </div>
    )
  }

  const placeOrder = async (e) => {
    e.preventDefault()
    setError('')
    setPlacing(true)
    try {
      await checkout({
        Items: items.map((i) => ({ ProductID: i.product.ProductID, Quantity: i.quantity })),
        ShippingAddress: address,
      })
      clearCart()
      navigate('/my-orders')
    } catch (err) {
      setError(err.response?.data?.detail || 'Checkout failed.')
    } finally {
      setPlacing(false)
    }
  }

  return (
    <div className="max-w-lg mx-auto">
      <h1 className="text-2xl font-bold mb-6">Checkout</h1>
      <form onSubmit={placeOrder} className="bg-white rounded-lg shadow p-6 space-y-4">
        <div>
          <label className="text-sm font-medium">Shipping Address</label>
          <textarea
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            required
            rows={3}
            className="border rounded-md px-3 py-2 w-full mt-1 text-sm"
          />
        </div>

        <div className="border-t pt-4">
          <p className="text-sm text-gray-500 mb-2">Order Summary</p>
          {items.map(({ product, quantity }) => (
            <div key={product.ProductID} className="flex justify-between text-sm py-1">
              <span>{product.ProductName} × {quantity}</span>
              <span>${(product.Price * quantity).toFixed(2)}</span>
            </div>
          ))}
          <div className="flex justify-between font-semibold mt-2 pt-2 border-t">
            <span>Total</span>
            <span>${total.toFixed(2)}</span>
          </div>
        </div>

        <p className="text-xs text-gray-400">
          Payment is simulated for this demo — no real payment gateway is used. Your order will be recorded
          with PaymentStatus = "Pending".
        </p>

        {error && <p className="text-sm text-red-600">{error}</p>}

        <button disabled={placing} className="bg-pitch-700 text-white w-full py-2.5 rounded-md font-medium hover:bg-pitch-800 disabled:opacity-50">
          {placing ? 'Placing Order...' : 'Place Order'}
        </button>
      </form>
    </div>
  )
}
