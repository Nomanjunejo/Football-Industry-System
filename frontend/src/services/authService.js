import api from './api'

export async function employeeLogin(email, password) {
  const form = new URLSearchParams()
  form.append('username', email)
  form.append('password', password)
  const { data } = await api.post('/api/auth/employee/login', form, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  })
  return data
}

export async function customerLogin(email, password) {
  const form = new URLSearchParams()
  form.append('username', email)
  form.append('password', password)
  const { data } = await api.post('/api/auth/customer/login', form, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  })
  return data
}

export async function customerRegister(payload) {
  const { data } = await api.post('/api/auth/customer/register', payload)
  return data
}

export function storeSession({ access_token, role, full_name, user_id }) {
  localStorage.setItem('token', access_token)
  localStorage.setItem('role', role)
  localStorage.setItem('full_name', full_name)
  localStorage.setItem('user_id', String(user_id))
}

export function clearSession() {
  localStorage.removeItem('token')
  localStorage.removeItem('role')
  localStorage.removeItem('full_name')
  localStorage.removeItem('user_id')
}
