import React, { useEffect, useState } from 'react'
import { getMyOrders } from '../../services/resourceService'
import Badge from '../../components/Badge'

export default function MyOrders() {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getMyOrders().then(setOrders).finally(() => setLoading(false))
  }, [])

  if (loading) return <p className="text-gray-400">Loading your orders...</p>
  if (orders.length === 0) return <p className="text-gray-500">You haven't placed any orders yet.</p>

  return (
    <div className="max-w-3xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">My Orders</h1>
      <div className="space-y-4">
        {orders.map((o) => (
          <div key={o.CustomerOrderID} className="bg-white rounded-lg shadow p-5">
            <div className="flex justify-between items-start">
              <div>
                <p className="font-medium">Order #{o.CustomerOrderID}</p>
                <p className="text-sm text-gray-400">{new Date(o.OrderDate).toLocaleString()}</p>
              </div>
              <div className="flex gap-2">
                <Badge value={o.PaymentStatus} />
                <Badge value={o.OrderStatus} />
              </div>
            </div>
            <div className="mt-3 divide-y">
              {o.items.map((item) => (
                <div key={item.CustomerOrderItemID} className="flex justify-between text-sm py-1.5">
                  <span>Product #{item.ProductID} × {item.Quantity}</span>
                  <span>${Number(item.LineTotal).toFixed(2)}</span>
                </div>
              ))}
            </div>
            <div className="flex justify-between mt-3 pt-3 border-t font-semibold">
              <span>Total</span>
              <span>${Number(o.TotalAmount).toFixed(2)}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
