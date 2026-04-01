'use client';

import { useQuery } from '@tanstack/react-query';
import { eventsApi } from '@/lib/api';
import { ListingCard } from '@/components/listings/listing-card';
import { useState } from 'react';

const eventTypes = ['all', 'cultural', 'adventure', 'food', 'wellness', 'nature', 'nightlife', 'sports', 'workshop'];

export default function EventsPage() {
  const [filter, setFilter] = useState('all');

  const { data, isLoading } = useQuery({
    queryKey: ['events', filter],
    queryFn: () => eventsApi.list(filter !== 'all' ? { event_type: filter } : {}),
  });

  const events = data?.data?.data || [];

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Events & Experiences</h1>

      <div className="flex gap-2 overflow-x-auto pb-2 mb-8">
        {eventTypes.map((type) => (
          <button
            key={type}
            onClick={() => setFilter(type)}
            className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap transition-colors ${
              filter === type ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {type === 'all' ? 'All' : type}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {[1, 2, 3].map((i) => <div key={i} className="bg-gray-100 rounded-xl h-72 animate-pulse" />)}
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {events.map((e: Record<string, unknown>) => (
            <ListingCard
              key={e.id as string}
              id={e.id as string}
              title={e.title as string}
              location={e.location as string}
              price={Number(e.price) > 0 ? `LKR ${e.price}` : 'Free'}
              image={(e.images as string[])?.[0]}
              href={`/events/${e.id}`}
              badge={e.event_type as string}
            />
          ))}
        </div>
      )}
    </div>
  );
}
