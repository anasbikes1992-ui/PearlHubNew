'use client';

import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { formatCurrency } from '@/lib/utils';

export default function AdminOverviewPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin', 'overview'],
    queryFn: () => adminApi.overview(),
  });

  const { data: taxiData } = useQuery({
    queryKey: ['admin', 'taxi-stats'],
    queryFn: () => adminApi.taxiStats(),
  });

  if (isLoading) return <div className="p-8">Loading...</div>;

  const stats = data?.data || {};
  const taxi = taxiData?.data || {};

  const cards = [
    { label: 'Total Users', value: stats.total_users, color: 'bg-blue-50 text-blue-700' },
    { label: 'Stays', value: stats.total_stays, color: 'bg-green-50 text-green-700' },
    { label: 'Vehicles', value: stats.total_vehicles, color: 'bg-purple-50 text-purple-700' },
    { label: 'Events', value: stats.total_events, color: 'bg-pink-50 text-pink-700' },
    { label: 'Properties', value: stats.total_properties, color: 'bg-amber-50 text-amber-700' },
    { label: 'SME', value: stats.total_sme, color: 'bg-cyan-50 text-cyan-700' },
    { label: 'Bookings', value: stats.total_bookings, color: 'bg-indigo-50 text-indigo-700' },
    { label: 'Revenue', value: formatCurrency(stats.total_revenue || 0), color: 'bg-emerald-50 text-emerald-700' },
  ];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Platform Overview</h1>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        {cards.map((card) => (
          <div key={card.label} className={`${card.color} rounded-xl p-4`}>
            <p className="text-sm opacity-70">{card.label}</p>
            <p className="text-2xl font-bold">{card.value ?? 0}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4">Pending Moderation</h2>
        <p className="text-3xl font-bold text-coral-400">{stats.pending_moderation || 0}</p>
        <p className="text-sm text-gray-500 mt-1">listings awaiting review</p>
      </div>

      <div className="bg-white rounded-xl border p-6">
        <h2 className="text-lg font-semibold mb-4">Taxi Service</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <p className="text-sm text-gray-500">Total Rides</p>
            <p className="text-xl font-bold">{taxi.total_rides || 0}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Completed</p>
            <p className="text-xl font-bold">{taxi.completed_rides || 0}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Total Fare</p>
            <p className="text-xl font-bold">{formatCurrency(taxi.total_fare || 0)}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Avg Rating</p>
            <p className="text-xl font-bold">{taxi.avg_rating || 'N/A'}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
