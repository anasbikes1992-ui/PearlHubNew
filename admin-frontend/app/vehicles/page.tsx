'use client';

import { useQuery } from '@tanstack/react-query';
import { vehiclesApi } from '@/lib/api';
import { ListingCard } from '@/components/listings/listing-card';
import { useState } from 'react';

const vehicleTypes = ['all', 'car', 'van', 'suv', 'bus', 'motorcycle', 'tuk_tuk', 'bicycle'];

export default function VehiclesPage() {
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['vehicles', filter, search],
    queryFn: () => vehiclesApi.list({
      ...(filter !== 'all' ? { vehicle_type: filter } : {}),
      ...(search ? { search } : {}),
    }),
  });

  const vehicles = data?.data?.data || [];

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Rent a Vehicle</h1>

      <div className="flex flex-col sm:flex-row gap-4 mb-8">
        <input
          type="text"
          placeholder="Search vehicles..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
        />
        <div className="flex gap-2 overflow-x-auto pb-2">
          {vehicleTypes.map((type) => (
            <button
              key={type}
              onClick={() => setFilter(type)}
              className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap transition-colors ${
                filter === type ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {type === 'all' ? 'All' : type.replace(/_/g, ' ')}
            </button>
          ))}
        </div>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {[1, 2, 3].map((i) => <div key={i} className="bg-gray-100 rounded-xl h-72 animate-pulse" />)}
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {vehicles.map((v: Record<string, unknown>) => (
            <ListingCard
              key={v.id as string}
              id={v.id as string}
              title={v.title as string}
              location={v.location as string}
              price={`LKR ${v.price_per_day}/day`}
              image={(v.images as string[])?.[0]}
              href={`/vehicles/${v.id}`}
              badge={v.vehicle_type as string}
            />
          ))}
        </div>
      )}
    </div>
  );
}
