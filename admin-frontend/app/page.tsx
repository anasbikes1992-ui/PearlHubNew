'use client';

import { useQuery } from '@tanstack/react-query';
import { staysApi, vehiclesApi, eventsApi } from '@/lib/api';
import { ListingCard } from '@/components/listings/listing-card';
import { Search } from 'lucide-react';
import Link from 'next/link';

const verticals = [
  { name: 'Stays', href: '/stays', icon: '🏨', color: 'bg-blue-50 text-blue-600' },
  { name: 'Vehicles', href: '/vehicles', icon: '🚗', color: 'bg-green-50 text-green-600' },
  { name: 'Events', href: '/events', icon: '🎉', color: 'bg-purple-50 text-purple-600' },
  { name: 'Properties', href: '/properties', icon: '🏠', color: 'bg-amber-50 text-amber-600' },
  { name: 'SME', href: '/sme', icon: '🏪', color: 'bg-pink-50 text-pink-600' },
  { name: 'Taxi', href: '/taxi', icon: '🚕', color: 'bg-yellow-50 text-yellow-600' },
  { name: 'Social', href: '/social', icon: '💬', color: 'bg-cyan-50 text-cyan-600' },
];

export default function HomePage() {
  const { data: stays } = useQuery({
    queryKey: ['stays', 'featured'],
    queryFn: () => staysApi.list(),
  });

  const { data: vehicles } = useQuery({
    queryKey: ['vehicles', 'featured'],
    queryFn: () => vehiclesApi.list(),
  });

  const { data: events } = useQuery({
    queryKey: ['events', 'featured'],
    queryFn: () => eventsApi.list(),
  });

  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-br from-primary-500 to-ocean-600 text-white py-20 px-4">
        <div className="max-w-6xl mx-auto text-center">
          <h1 className="text-4xl md:text-6xl font-bold mb-4">
            Discover Sri Lanka
          </h1>
          <p className="text-lg md:text-xl opacity-90 mb-8 max-w-2xl mx-auto">
            Your gateway to stays, vehicles, events, properties, and local experiences across the Pearl of the Indian Ocean
          </p>
          <div className="max-w-xl mx-auto relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search stays, vehicles, events..."
              className="w-full pl-12 pr-4 py-4 rounded-xl text-gray-900 text-lg focus:outline-none focus:ring-4 focus:ring-white/30"
            />
          </div>
        </div>
      </section>

      {/* Quick Access */}
      <section className="max-w-6xl mx-auto px-4 -mt-10">
        <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-7 gap-3">
          {verticals.map((v) => (
            <Link
              key={v.name}
              href={v.href}
              className={`${v.color} rounded-xl p-4 text-center hover:shadow-lg transition-shadow`}
            >
              <span className="text-2xl block mb-1">{v.icon}</span>
              <span className="text-sm font-medium">{v.name}</span>
            </Link>
          ))}
        </div>
      </section>

      {/* Featured Stays */}
      <section className="max-w-6xl mx-auto px-4 py-12">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold">Popular Stays</h2>
          <Link href="/stays" className="text-primary-500 hover:underline text-sm font-medium">
            View all
          </Link>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {(stays?.data?.data || []).slice(0, 3).map((stay: Record<string, unknown>) => (
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
      </section>

      {/* Featured Vehicles */}
      <section className="max-w-6xl mx-auto px-4 pb-12">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold">Rent a Vehicle</h2>
          <Link href="/vehicles" className="text-primary-500 hover:underline text-sm font-medium">
            View all
          </Link>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {(vehicles?.data?.data || []).slice(0, 3).map((v: Record<string, unknown>) => (
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
      </section>

      {/* Featured Events */}
      <section className="max-w-6xl mx-auto px-4 pb-16">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold">Upcoming Events</h2>
          <Link href="/events" className="text-primary-500 hover:underline text-sm font-medium">
            View all
          </Link>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {(events?.data?.data || []).slice(0, 3).map((e: Record<string, unknown>) => (
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
      </section>
    </div>
  );
}
