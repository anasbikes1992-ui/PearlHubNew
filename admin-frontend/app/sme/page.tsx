'use client';

import { useQuery } from '@tanstack/react-query';
import { smeApi } from '@/lib/api';
import Link from 'next/link';
import { MapPin } from 'lucide-react';
import { useState } from 'react';

const bizTypes = ['all', 'restaurant', 'shop', 'service', 'craft', 'tour_operator', 'other'];

export default function SmePage() {
  const [filter, setFilter] = useState('all');

  const { data, isLoading } = useQuery({
    queryKey: ['sme', filter],
    queryFn: () => smeApi.list(filter !== 'all' ? { business_type: filter } : {}),
  });

  const businesses = data?.data?.data || [];

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Local Businesses</h1>

      <div className="flex gap-2 overflow-x-auto pb-2 mb-8">
        {bizTypes.map((type) => (
          <button
            key={type}
            onClick={() => setFilter(type)}
            className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap transition-colors ${
              filter === type ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-600'
            }`}
          >
            {type === 'all' ? 'All' : type.replace(/_/g, ' ')}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {[1, 2, 3].map((i) => <div key={i} className="bg-gray-100 rounded-xl h-48 animate-pulse" />)}
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {businesses.map((b: Record<string, unknown>) => (
            <Link key={b.id as string} href={`/sme/${b.id}`} className="block group">
              <div className="bg-white rounded-xl border p-5 hover:shadow-lg transition-shadow">
                <div className="flex items-center gap-3 mb-3">
                  {b.logo_url ? (
                    <img src={b.logo_url as string} alt="" className="w-12 h-12 rounded-full object-cover" />
                  ) : (
                    <div className="w-12 h-12 rounded-full bg-pink-100 flex items-center justify-center text-xl">🏪</div>
                  )}
                  <div>
                    <h3 className="font-semibold">{b.business_name as string}</h3>
                    <span className="text-xs bg-gray-100 px-2 py-0.5 rounded-full capitalize">
                      {(b.business_type as string).replace(/_/g, ' ')}
                    </span>
                  </div>
                </div>
                {b.description && (
                  <p className="text-sm text-gray-500 line-clamp-2">{b.description as string}</p>
                )}
                <div className="flex items-center gap-1 text-gray-400 text-xs mt-3">
                  <MapPin className="w-3 h-3" />
                  <span>{b.location as string}</span>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
