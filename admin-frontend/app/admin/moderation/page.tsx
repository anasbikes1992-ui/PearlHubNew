'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import { Check, X } from 'lucide-react';

const verticals = ['stays', 'vehicles', 'events', 'properties', 'sme'] as const;
const typeMap: Record<string, string> = {
  stays: 'stay', vehicles: 'vehicle', events: 'event', properties: 'property', sme: 'sme',
};

export default function ModerationPage() {
  const [tab, setTab] = useState<typeof verticals[number]>('stays');
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin', 'pending'],
    queryFn: () => adminApi.pendingListings(),
  });

  const moderate = useMutation({
    mutationFn: (params: { listing_type: string; listing_id: string; status: string; admin_note?: string }) =>
      adminApi.moderateListing(params),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'pending'] }),
  });

  const pending = data?.data || {};
  const listings = pending[tab] || [];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Listing Moderation</h1>

      <div className="flex gap-2 mb-6">
        {verticals.map((v) => (
          <button
            key={v}
            onClick={() => setTab(v)}
            className={`px-4 py-2 rounded-lg text-sm font-medium capitalize transition-colors ${
              tab === v ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-600'
            }`}
          >
            {v} ({(pending[v] || []).length})
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => <div key={i} className="bg-gray-100 rounded-xl h-20 animate-pulse" />)}
        </div>
      ) : listings.length === 0 ? (
        <p className="text-gray-400 text-center py-10">No pending listings in {tab}.</p>
      ) : (
        <div className="space-y-3">
          {listings.map((listing: Record<string, unknown>) => (
            <div key={listing.id as string} className="bg-white rounded-xl border p-4 flex items-center justify-between">
              <div>
                <p className="font-medium">{(listing.title || listing.business_name) as string}</p>
                <p className="text-sm text-gray-500">
                  by {(listing.owner as Record<string, string>)?.full_name || 'Unknown'} -
                  {' '}{(listing.location || '') as string}
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => moderate.mutate({
                    listing_type: typeMap[tab],
                    listing_id: listing.id as string,
                    status: 'approved',
                  })}
                  className="bg-green-500 text-white p-2 rounded-lg hover:bg-green-600"
                  title="Approve"
                >
                  <Check className="w-4 h-4" />
                </button>
                <button
                  onClick={() => {
                    const note = prompt('Rejection reason (optional):');
                    moderate.mutate({
                      listing_type: typeMap[tab],
                      listing_id: listing.id as string,
                      status: 'rejected',
                      admin_note: note || undefined,
                    });
                  }}
                  className="bg-red-100 text-red-600 p-2 rounded-lg hover:bg-red-200"
                  title="Reject"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
