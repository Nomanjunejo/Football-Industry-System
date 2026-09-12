import React, { createContext, useContext, useState, useMemo } from 'react'

const CartContext = createContext(null)

export function CartProvider({ children }) {
  const [items, setItems] = useState([]) // [{ product, quantity }]

  const addToCart = (product, quantity = 1) => {
    setItems((prev) => {
      const existing = prev.find((i) => i.product.ProductID === product.ProductID)
      if (existing) {
        return prev.map((i) =>
          i.product.ProductID === product.ProductID ? { ...i, quantity: i.quantity + quantity } : i,
        )
      }
      return [...prev, { product, quantity }]
    })
  }

  const removeFromCart = (productId) => {
    setItems((prev) => prev.filter((i) => i.product.ProductID !== productId))
  }

  const updateQuantity = (productId, quantity) => {
    setItems((prev) => prev.map((i) => (i.product.ProductID === productId ? { ...i, quantity } : i)))
  }

  const clearCart = () => setItems([])

  const total = useMemo(
    () => items.reduce((sum, i) => sum + Number(i.product.Price) * i.quantity, 0),
    [items],
  )

  return (
    <CartContext.Provider value={{ items, addToCart, removeFromCart, updateQuantity, clearCart, total }}>
      {children}
    </CartContext.Provider>
  )
}

export function useCart() {
  const ctx = useContext(CartContext)
  if (!ctx) throw new Error('useCart must be used within CartProvider')
  return ctx
}
