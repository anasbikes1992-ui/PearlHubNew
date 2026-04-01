'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { formatDate } from '@/lib/utils';
import { Check, X } from 'lucide-react';

export default function KycReviewPage() {
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin', 'kyc'],
    queryFn: () => adminApi.kycReview(),
  });

  const approve = useMutation({
    mutationFn: (id: string) => adminApi.approveKyc(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'kyc'] }),
  });

  const reject = useMutation({
    mutationFn: ({ id, note }: { id: string; note?: string }) => adminApi.rejectKyc(id, note),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'kyc'] }),
  });

  const applications = data?.data || [];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">KYC Review</h1>

      {isLoading ? (
        <div className="space-y-3">
          {[1, 2].map((i) => <div key={i} className="bg-gray-100 rounded-xl h-32 animate-pulse" />)}
        </div>
      ) : applications.length === 0 ? (
        <p className="text-gray-400 text-center py-10">No pending KYC applications.</p>
      ) : (
        <div className="space-y-4">
          {applications.map((kyc: Record<string, unknown>) => (
            <div key={kyc.id as string} className="bg-white rounded-xl border p-5">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <p className="font-semibold">{(kyc.driver as Record<string, string>)?.full_name || 'Driver'}</p>
                  <p className="text-sm text-gray-500">{(kyc.driver as Record<string, string>)?.email}</p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => approve.mutate(kyc.id as string)}
                    className="bg-green-500 text-white px-3 py-1.5 rounded-lg text-sm flex items-center gap-1"
                  >
                    <Check className="w-4 h-4" /> Approve
                  </button>
                  <button
                    onClick={() => {
                      const note = prompt('Rejection reason:');
                      reject.mutate({ id: kyc.id as string, note: note || undefined });
                    }}
                    className="bg-red-100 text-red-600 px-3 py-1.5 rounded-lg text-sm flex items-center gap-1"
                  >
                    <X className="w-4 h-4" /> Reject
                  </button>
                </div>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                <div>
                  <p className="text-gray-400">License #</p>
                  <p className="font-medium">{kyc.license_number as string}</p>
                </div>
                <div>
                  <p className="text-gray-400">License Expiry</p>
                  <p className="font-medium">{formatDate(kyc.license_expiry as string)}</p>
                </div>
                <div>
                  <p className="text-gray-400">Vehicle Reg</p>
                  <p className="font-medium">{kyc.vehicle_registration as string}</p>
                </div>
                <div>
                  <p className="text-gray-400">Vehicle Type</p>
                  <p className="font-medium">{kyc.vehicle_type as string}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
