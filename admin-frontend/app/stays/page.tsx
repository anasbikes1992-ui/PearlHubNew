'use client';

import { useQuery } from '@tanstack/react-query';
import { staysApi } from '@/lib/api';
import { ListingCard } from '@/components/listings/listing-card';
import { useState } from 'react';

const stayTypes = ['all', 'hotel', 'villa', 'apartment', 'guest_house', 'boutique', 'resort', 'hostel'];

export default function StaysPage() {
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['stays', filter, search],
    queryFn: () => staysApi.list({
      ...(filter !== 'all' ? { stay_type: filter } : {}),
      ...(search ? { search } : {}),
    }),
  });

  const stays = data?.data?.data || [];

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Stays in Sri Lanka</h1>

      <div className="flex flex-col sm:flex-row gap-4 mb-8">
        <input
          type="text"
          placeholder="Search stays..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
        />
        <div className="flex gap-2 overflow-x-auto pb-2">
          {stayTypes.map((type) => (
            <button
              key={type}
              onClick={() => setFilter(type)}
              className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap transition-colors ${
                filter === type
                  ? 'bg-primary-500 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {type === 'all' ? 'All' : type.replace(/_/g, ' ')}
            </button>
          ))}
        </div>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <div key={i} className="bg-gray-100 rounded-xl h-72 animate-pulse" />
          ))}
        </div>
      ) : stays.length === 0 ? (
        <div className="text-center py-20 text-gray-500">No stays found. Try adjusting your filters.</div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {stays.map((stay: Record<string, unknown>) => (
            <ListingCard
              key={stay.id as string}
              id={stay.id as string}
              title={stay.title as string}
              location={stay.location as string}
              price={`LKR ${stay.price_per_night}/night`}
              image={(stay.images as string[])?.[0]}
              href={`/stays/${stay.id}`}
              badge={stay.stay_type as string}
            />
          ))}
        </div>
      )}
    </div>
  );
}
