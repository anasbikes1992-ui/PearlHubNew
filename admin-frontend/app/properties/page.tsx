'use client';

import { useQuery } from '@tanstack/react-query';
import { propertiesApi } from '@/lib/api';
import { ListingCard } from '@/components/listings/listing-card';
import { useState } from 'react';
import { formatCurrency } from '@/lib/utils';

const propertyTypes = ['all', 'house', 'apartment', 'land', 'commercial', 'villa'];

export default function PropertiesPage() {
  const [filter, setFilter] = useState('all');
  const [listingType, setListingType] = useState<'all' | 'sale' | 'rent'>('all');

  const { data, isLoading } = useQuery({
    queryKey: ['properties', filter, listingType],
    queryFn: () => propertiesApi.list({
      ...(filter !== 'all' ? { property_type: filter } : {}),
      ...(listingType !== 'all' ? { listing_type: listingType } : {}),
    }),
  });

  const properties = data?.data?.data || [];

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Properties</h1>

      <div className="flex flex-col sm:flex-row gap-4 mb-8">
        <div className="flex gap-2">
          {(['all', 'sale', 'rent'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setListingType(t)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                listingType === t ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-600'
              }`}
            >
              {t === 'all' ? 'All' : t === 'sale' ? 'For Sale' : 'For Rent'}
            </button>
          ))}
        </div>
        <div className="flex gap-2 overflow-x-auto pb-2">
          {propertyTypes.map((type) => (
            <button
              key={type}
              onClick={() => setFilter(type)}
              className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap transition-colors ${
                filter === type ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-600'
              }`}
            >
              {type === 'all' ? 'All Types' : type}
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
          {properties.map((p: Record<string, unknown>) => (
            <ListingCard
              key={p.id as string}
              id={p.id as string}
              title={p.title as string}
              location={p.location as string}
              price={formatCurrency(Number(p.price))}
              image={(p.images as string[])?.[0]}
              href={`/properties/${p.id}`}
              badge={`${p.property_type} - ${p.listing_type}`}
            />
          ))}
        </div>
      )}
    </div>
  );
}
