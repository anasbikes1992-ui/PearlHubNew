import axios from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('pearlhub_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 && typeof window !== 'undefined') {
      localStorage.removeItem('pearlhub_token');
      window.location.href = '/auth';
    }
    return Promise.reject(error);
  }
);

export default api;

// Auth
export const authApi = {
  register: (data: { name: string; email: string; password: string; password_confirmation: string; role?: string }) =>
    api.post('/auth/register', data),
  login: (data: { email: string; password: string }) =>
    api.post('/auth/login', data),
  logout: () => api.post('/auth/logout'),
  me: () => api.get('/auth/me'),
  updateProfile: (data: Record<string, string>) => api.put('/auth/profile', data),
};

// Listings
export const staysApi = {
  list: (params?: Record<string, string>) => api.get('/stays', { params }),
  get: (id: string) => api.get(`/stays/${id}`),
  create: (data: Record<string, unknown>) => api.post('/stays', data),
  update: (id: string, data: Record<string, unknown>) => api.put(`/stays/${id}`, data),
  delete: (id: string) => api.delete(`/stays/${id}`),
  my: () => api.get('/my/stays'),
};

export const vehiclesApi = {
  list: (params?: Record<string, string>) => api.get('/vehicles', { params }),
  get: (id: string) => api.get(`/vehicles/${id}`),
  create: (data: Record<string, unknown>) => api.post('/vehicles', data),
  update: (id: string, data: Record<string, unknown>) => api.put(`/vehicles/${id}`, data),
  delete: (id: string) => api.delete(`/vehicles/${id}`),
  my: () => api.get('/my/vehicles'),
};

export const eventsApi = {
  list: (params?: Record<string, string>) => api.get('/events', { params }),
  get: (id: string) => api.get(`/events/${id}`),
  create: (data: Record<string, unknown>) => api.post('/events', data),
  update: (id: string, data: Record<string, unknown>) => api.put(`/events/${id}`, data),
  delete: (id: string) => api.delete(`/events/${id}`),
  my: () => api.get('/my/events'),
};

export const propertiesApi = {
  list: (params?: Record<string, string>) => api.get('/properties', { params }),
  get: (id: string) => api.get(`/properties/${id}`),
  create: (data: Record<string, unknown>) => api.post('/properties', data),
  update: (id: string, data: Record<string, unknown>) => api.put(`/properties/${id}`, data),
  delete: (id: string) => api.delete(`/properties/${id}`),
  my: () => api.get('/my/properties'),
};

export const smeApi = {
  list: (params?: Record<string, string>) => api.get('/sme', { params }),
  get: (id: string) => api.get(`/sme/${id}`),
  products: (id: string) => api.get(`/sme/${id}/products`),
  create: (data: Record<string, unknown>) => api.post('/sme', data),
  update: (id: string, data: Record<string, unknown>) => api.put(`/sme/${id}`, data),
  delete: (id: string) => api.delete(`/sme/${id}`),
  my: () => api.get('/my/sme'),
};

// Bookings
export const bookingsApi = {
  list: () => api.get('/bookings'),
  create: (data: Record<string, unknown>) => api.post('/bookings', data),
  get: (id: string) => api.get(`/bookings/${id}`),
  cancel: (id: string) => api.post(`/bookings/${id}/cancel`),
  providerBookings: () => api.get('/provider/bookings'),
  updateStatus: (id: string, status: string) => api.put(`/provider/bookings/${id}/status`, { status }),
};

// Reviews
export const reviewsApi = {
  list: (listingId: string, listingType: string) =>
    api.get('/reviews', { params: { listing_id: listingId, listing_type: listingType } }),
  create: (data: Record<string, unknown>) => api.post('/reviews', data),
  delete: (id: string) => api.delete(`/reviews/${id}`),
};

// Wallet
export const walletApi = {
  balance: () => api.get('/wallet/balance'),
  transactions: () => api.get('/wallet/transactions'),
  deposit: (amount: number) => api.post('/wallet/deposit', { amount }),
  withdraw: (amount: number) => api.post('/wallet/withdraw', { amount }),
};

// Taxi
export const taxiApi = {
  requestRide: (data: Record<string, unknown>) => api.post('/taxi/request', data),
  activeRide: () => api.get('/taxi/active'),
  history: () => api.get('/taxi/history'),
  cancel: (id: string) => api.post(`/taxi/${id}/cancel`),
  rate: (id: string, data: { rating: number; rating_comment?: string }) => api.post(`/taxi/${id}/rate`, data),
  nearbyDrivers: (lat: number, lng: number) => api.get('/taxi/nearby-drivers', { params: { lat, lng } }),
  applyPromo: (code: string, fare: number) => api.post('/taxi/apply-promo', { code, fare }),
  calculateFare: (data: Record<string, unknown>) => api.post('/taxi/calculate-fare', data),
};

// Social
export const socialApi = {
  feed: () => api.get('/social/feed'),
  create: (data: { content: string; images?: string[] }) => api.post('/social', data),
  like: (id: string) => api.post(`/social/${id}/like`),
  delete: (id: string) => api.delete(`/social/${id}`),
};

// Search
export const searchApi = {
  global: (q: string) => api.get('/search', { params: { q } }),
};

// AI Concierge
export const aiApi = {
  query: (message: string) => api.post('/ai/concierge', { message }),
};

// Admin
export const adminApi = {
  overview: () => api.get('/admin/overview'),
  pendingListings: () => api.get('/admin/pending-listings'),
  moderateListing: (data: Record<string, unknown>) => api.post('/admin/moderate-listing', data),
  users: (params?: Record<string, string>) => api.get('/admin/users', { params }),
  updateUserRole: (id: string, role: string) => api.put(`/admin/users/${id}/role`, { role }),
  settings: () => api.get('/admin/settings'),
  updateSetting: (key: string, value: string) => api.post('/admin/settings', { key, value }),
  taxiStats: () => api.get('/admin/taxi-stats'),
  kycReview: () => api.get('/admin/kyc-review'),
  approveKyc: (id: string) => api.post(`/admin/kyc/${id}/approve`),
  rejectKyc: (id: string, note?: string) => api.post(`/admin/kyc/${id}/reject`, { note }),
  actions: () => api.get('/admin/actions'),
};
