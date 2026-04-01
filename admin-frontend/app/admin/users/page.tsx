'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';

const roles = ['customer', 'stays_provider', 'vehicle_provider', 'event_organizer', 'property_owner', 'taxi_driver', 'sme_owner', 'admin'];

export default function UsersPage() {
  const [roleFilter, setRoleFilter] = useState('');
  const [search, setSearch] = useState('');
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin', 'users', roleFilter, search],
    queryFn: () => adminApi.users({
      ...(roleFilter ? { role: roleFilter } : {}),
      ...(search ? { search } : {}),
    }),
  });

  const updateRole = useMutation({
    mutationFn: ({ id, role }: { id: string; role: string }) => adminApi.updateUserRole(id, role),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'users'] }),
  });

  const users = data?.data?.data || [];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">User Management</h1>

      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <input
          type="text"
          placeholder="Search by name or email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="flex-1 px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        />
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="px-3 py-2 border rounded-lg text-sm"
        >
          <option value="">All Roles</option>
          {roles.map((r) => (
            <option key={r} value={r}>{r.replace(/_/g, ' ')}</option>
          ))}
        </select>
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => <div key={i} className="bg-gray-100 rounded-xl h-16 animate-pulse" />)}
        </div>
      ) : (
        <div className="bg-white rounded-xl border overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500">
              <tr>
                <th className="text-left px-4 py-3">Name</th>
                <th className="text-left px-4 py-3">Email</th>
                <th className="text-left px-4 py-3">Role</th>
                <th className="text-left px-4 py-3">Verified</th>
                <th className="text-left px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {users.map((u: Record<string, unknown>) => (
                <tr key={u.id as string}>
                  <td className="px-4 py-3 font-medium">{u.full_name as string}</td>
                  <td className="px-4 py-3 text-gray-500">{u.email as string}</td>
                  <td className="px-4 py-3">
                    <span className="capitalize text-xs bg-gray-100 px-2 py-1 rounded-full">
                      {(u.role as string).replace(/_/g, ' ')}
                    </span>
                  </td>
                  <td className="px-4 py-3">{u.verified ? '✓' : '—'}</td>
                  <td className="px-4 py-3">
                    <select
                      value={u.role as string}
                      onChange={(e) => updateRole.mutate({ id: u.id as string, role: e.target.value })}
                      className="text-xs border rounded px-2 py-1"
                    >
                      {roles.map((r) => (
                        <option key={r} value={r}>{r.replace(/_/g, ' ')}</option>
                      ))}
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
