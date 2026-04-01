'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { bookingsApi, staysApi } from '@/lib/api';
import { useAuthStore } from '@/lib/auth-store';
import { formatCurrency, formatDate } from '@/lib/utils';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import Link from 'next/link';

export default function DashboardPage() {
  const { user, isProvider, loading } = useAuthStore();
  const router = useRouter();
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!loading && !user) router.push('/auth');
  }, [user, loading, router]);

  const { data: bookings } = useQuery({
    queryKey: ['bookings'],
    queryFn: () => bookingsApi.list(),
    enabled: !!user,
  });

  const { data: providerBookings } = useQuery({
    queryKey: ['provider-bookings'],
    queryFn: () => bookingsApi.providerBookings(),
    enabled: !!user && isProvider(),
  });

  const { data: myStays } = useQuery({
    queryKey: ['my-stays'],
    queryFn: () => staysApi.my(),
    enabled: !!user && isProvider(),
  });

  const updateStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      bookingsApi.updateStatus(id, status),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['provider-bookings'] }),
  });

  if (loading || !user) return null;

  const myBookings = bookings?.data?.data || [];
  const receivedBookings = providerBookings?.data?.data || [];
  const listings = myStays?.data?.data || [];

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-2">Dashboard</h1>
      <p className="text-gray-500 mb-8">Welcome, {user.profile?.full_name || user.name}</p>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-white rounded-xl border p-4">
          <p className="text-sm text-gray-500">Role</p>
          <p className="text-lg font-semibold capitalize">{user.profile?.role.replace(/_/g, ' ')}</p>
        </div>
        <div className="bg-white rounded-xl border p-4">
          <p className="text-sm text-gray-500">Tier</p>
          <p className="text-lg font-semibold capitalize">{user.profile?.provider_tier}</p>
        </div>
        <div className="bg-white rounded-xl border p-4">
          <p className="text-sm text-gray-500">My Bookings</p>
          <p className="text-lg font-semibold">{myBookings.length}</p>
        </div>
        {isProvider() && (
          <div className="bg-white rounded-xl border p-4">
            <p className="text-sm text-gray-500">My Listings</p>
            <p className="text-lg font-semibold">{listings.length}</p>
          </div>
        )}
      </div>

      {/* My Bookings */}
      <section className="mb-10">
        <h2 className="text-xl font-bold mb-4">My Bookings</h2>
        {myBookings.length === 0 ? (
          <p className="text-gray-400 text-sm">No bookings yet. <Link href="/" className="text-primary-500">Browse listings</Link></p>
        ) : (
          <div className="space-y-3">
            {myBookings.slice(0, 5).map((b: Record<string, unknown>) => (
              <div key={b.id as string} className="bg-white rounded-xl border p-4 flex items-center justify-between">
                <div>
                  <p className="font-medium">{b.listing_type as string} booking</p>
                  <p className="text-sm text-gray-500">
                    {b.check_in ? `${formatDate(b.check_in as string)} - ${formatDate(b.check_out as string)}` : 'N/A'}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-bold">{formatCurrency(Number(b.total_price))}</p>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${
                    b.status === 'confirmed' ? 'bg-green-100 text-green-700' :
                    b.status === 'cancelled' ? 'bg-red-100 text-red-700' :
                    'bg-yellow-100 text-yellow-700'
                  }`}>
                    {b.status as string}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Provider: Received Bookings */}
      {isProvider() && (
        <section>
          <h2 className="text-xl font-bold mb-4">Received Bookings</h2>
          {receivedBookings.length === 0 ? (
            <p className="text-gray-400 text-sm">No bookings received yet.</p>
          ) : (
            <div className="space-y-3">
              {receivedBookings.slice(0, 10).map((b: Record<string, unknown>) => (
                <div key={b.id as string} className="bg-white rounded-xl border p-4 flex items-center justify-between">
                  <div>
                    <p className="font-medium">{(b.user as Record<string, string>)?.full_name || 'Customer'}</p>
                    <p className="text-sm text-gray-500">{b.listing_type as string} - {formatCurrency(Number(b.total_price))}</p>
                  </div>
                  <div className="flex gap-2">
                    {b.status === 'pending' && (
                      <>
                        <button
                          onClick={() => updateStatus.mutate({ id: b.id as string, status: 'confirmed' })}
                          className="bg-green-500 text-white px-3 py-1.5 rounded-lg text-xs font-medium"
                        >
                          Confirm
                        </button>
                        <button
                          onClick={() => updateStatus.mutate({ id: b.id as string, status: 'cancelled' })}
                          className="bg-red-100 text-red-600 px-3 py-1.5 rounded-lg text-xs font-medium"
                        >
                          Cancel
                        </button>
                      </>
                    )}
                    {b.status === 'confirmed' && (
                      <button
                        onClick={() => updateStatus.mutate({ id: b.id as string, status: 'completed' })}
                        className="bg-primary-500 text-white px-3 py-1.5 rounded-lg text-xs font-medium"
                      >
                        Complete
                      </button>
                    )}
                    {(b.status !== 'pending' && b.status !== 'confirmed') && (
                      <span className="text-xs text-gray-400 capitalize">{b.status as string}</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
      )}
    </div>
  );
}
