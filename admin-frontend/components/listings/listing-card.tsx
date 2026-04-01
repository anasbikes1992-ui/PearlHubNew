'use client';

import Link from 'next/link';
import { MapPin } from 'lucide-react';

interface ListingCardProps {
  id: string;
  title: string;
  location: string;
  price: string;
  image?: string;
  href: string;
  badge?: string;
}

export function ListingCard({ title, location, price, image, href, badge }: ListingCardProps) {
  return (
    <Link href={href} className="group block">
      <div className="bg-white rounded-xl overflow-hidden border border-gray-200 hover:shadow-lg transition-shadow">
        <div className="aspect-[4/3] bg-gray-100 relative overflow-hidden">
          {image ? (
            <img
              src={image}
              alt={title}
              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-gray-400 text-4xl">
              🏝️
            </div>
          )}
          {badge && (
            <span className="absolute top-3 left-3 bg-white/90 backdrop-blur text-xs font-medium px-2 py-1 rounded-full capitalize">
              {badge.replace(/_/g, ' ')}
            </span>
          )}
        </div>
        <div className="p-4">
          <h3 className="font-semibold text-gray-900 truncate">{title}</h3>
          <div className="flex items-center gap-1 text-gray-500 text-sm mt-1">
            <MapPin className="w-3.5 h-3.5" />
            <span className="truncate">{location}</span>
          </div>
          <p className="mt-2 font-bold text-primary-500">{price}</p>
        </div>
      </div>
    </Link>
  );
}
