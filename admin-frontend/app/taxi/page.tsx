'use client';

import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { taxiApi } from '@/lib/api';
import { useAuthStore } from '@/lib/auth-store';
import { formatCurrency } from '@/lib/utils';
import { MapPin, Navigation, Clock } from 'lucide-react';

const categories = [
  { slug: 'tuk-tuk', name: 'Tuk Tuk', icon: '🛺', passengers: 3 },
  { slug: 'mini', name: 'Mini', icon: '🚗', passengers: 4 },
  { slug: 'sedan', name: 'Sedan', icon: '🚙', passengers: 4 },
  { slug: 'premium', name: 'Premium', icon: '✨', passengers: 4 },
  { slug: 'suv', name: 'SUV', icon: '🚐', passengers: 6 },
  { slug: 'van', name: 'Van', icon: '🚌', passengers: 8 },
  { slug: 'mini-bus', name: 'Mini Bus', icon: '🚍', passengers: 15 },
  { slug: 'luxury', name: 'Luxury', icon: '💎', passengers: 4 },
  { slug: 'motorcycle', name: 'Motorcycle', icon: '🏍️', passengers: 1 },
  { slug: 'women-only', name: 'Women Only', icon: '👩', passengers: 4 },
  { slug: 'eco', name: 'Eco', icon: '🌿', passengers: 4 },
  { slug: 'parcel', name: 'Parcel', icon: '📦', passengers: 0 },
  { slug: 'airport-transfer', name: 'Airport', icon: '✈️', passengers: 4 },
];

export default function TaxiPage() {
  const user = useAuthStore((s) => s.user);
  const [selectedCategory, setSelectedCategory] = useState('sedan');
  const [pickup, setPickup] = useState({ lat: 6.9271, lng: 79.8612, address: '' });
  const [dropoff, setDropoff] = useState({ lat: 0, lng: 0, address: '' });
  const [fareEstimate, setFareEstimate] = useState<{ fare: number; distance_km: number } | null>(null);
  const [promoCode, setPromoCode] = useState('');

  const { data: activeRide } = useQuery({
    queryKey: ['taxi', 'active'],
    queryFn: () => taxiApi.activeRide(),
    enabled: !!user,
    refetchInterval: 5000,
  });

  const estimateFare = useMutation({
    mutationFn: () => taxiApi.calculateFare({
      vehicle_category_slug: selectedCategory,
      pickup_lat: pickup.lat,
      pickup_lng: pickup.lng,
      dropoff_lat: dropoff.lat,
      dropoff_lng: dropoff.lng,
    }),
    onSuccess: ({ data }) => setFareEstimate(data),
  });

  const requestRide = useMutation({
    mutationFn: () => taxiApi.requestRide({
      vehicle_category_slug: selectedCategory,
      pickup_lat: pickup.lat,
      pickup_lng: pickup.lng,
      pickup_address: pickup.address,
      dropoff_lat: dropoff.lat,
      dropoff_lng: dropoff.lng,
      dropoff_address: dropoff.address,
      promo_code: promoCode || undefined,
    }),
  });

  const ride = activeRide?.data;

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">PearlRide Taxi</h1>

      {ride && ride.status !== 'completed' && ride.status !== 'cancelled' ? (
        <div className="bg-white rounded-xl border p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold">Active Ride</h2>
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${
              ride.status === 'in_progress' ? 'bg-green-100 text-green-700' :
              ride.status === 'accepted' ? 'bg-blue-100 text-blue-700' :
              ride.status === 'arrived' ? 'bg-purple-100 text-purple-700' :
              'bg-yellow-100 text-yellow-700'
            }`}>
              {ride.status.replace(/_/g, ' ')}
            </span>
          </div>
          <div className="space-y-2 text-sm">
            <div className="flex items-center gap-2">
              <MapPin className="w-4 h-4 text-green-500" />
              <span>{ride.pickup_address || 'Pickup location'}</span>
            </div>
            <div className="flex items-center gap-2">
              <Navigation className="w-4 h-4 text-red-500" />
              <span>{ride.dropoff_address || 'Dropoff location'}</span>
            </div>
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-gray-400" />
              <span>Fare: {formatCurrency(ride.fare)}</span>
            </div>
          </div>
          {ride.driver && (
            <div className="mt-4 pt-4 border-t flex items-center gap-3">
              <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-bold">
                {ride.driver.full_name?.[0] || 'D'}
              </div>
              <div>
                <p className="font-medium">{ride.driver.full_name}</p>
                <p className="text-xs text-gray-500">{ride.vehicle_category_slug}</p>
              </div>
            </div>
          )}
        </div>
      ) : (
        <>
          {/* Location inputs */}
          <div className="bg-white rounded-xl border p-6 mb-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Pickup</label>
              <input
                type="text"
                placeholder="Enter pickup address"
                value={pickup.address}
                onChange={(e) => setPickup({ ...pickup, address: e.target.value })}
                className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Dropoff</label>
              <input
                type="text"
                placeholder="Enter dropoff address"
                value={dropoff.address}
                onChange={(e) => setDropoff({ ...dropoff, address: e.target.value, lat: 7.2906, lng: 80.6337 })}
                className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
          </div>

          {/* Vehicle categories */}
          <div className="mb-6">
            <h2 className="text-lg font-semibold mb-3">Choose Vehicle</h2>
            <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-2">
              {categories.map((cat) => (
                <button
                  key={cat.slug}
                  onClick={() => setSelectedCategory(cat.slug)}
                  className={`p-3 rounded-xl text-center transition-all ${
                    selectedCategory === cat.slug
                      ? 'bg-primary-500 text-white shadow-lg scale-105'
                      : 'bg-white border hover:border-primary-300'
                  }`}
                >
                  <span className="text-2xl block">{cat.icon}</span>
                  <span className="text-xs font-medium block mt-1">{cat.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Promo */}
          <div className="bg-white rounded-xl border p-4 mb-6">
            <input
              type="text"
              placeholder="Promo code (optional)"
              value={promoCode}
              onChange={(e) => setPromoCode(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          {/* Fare estimate */}
          {fareEstimate && (
            <div className="bg-green-50 rounded-xl p-4 mb-6 flex items-center justify-between">
              <div>
                <p className="text-sm text-green-700">Estimated Fare</p>
                <p className="text-2xl font-bold text-green-800">{formatCurrency(fareEstimate.fare)}</p>
              </div>
              <p className="text-sm text-green-600">{fareEstimate.distance_km} km</p>
            </div>
          )}

          <div className="flex gap-3">
            <button
              onClick={() => estimateFare.mutate()}
              disabled={!dropoff.lat}
              className="flex-1 bg-gray-100 text-gray-700 py-3 rounded-xl font-medium hover:bg-gray-200 disabled:opacity-50"
            >
              Estimate Fare
            </button>
            <button
              onClick={() => requestRide.mutate()}
              disabled={!user || !dropoff.lat || requestRide.isPending}
              className="flex-1 bg-primary-500 text-white py-3 rounded-xl font-medium hover:bg-primary-600 disabled:opacity-50"
            >
              {requestRide.isPending ? 'Requesting...' : 'Request Ride'}
            </button>
          </div>
        </>
      )}
    </div>
  );
}
