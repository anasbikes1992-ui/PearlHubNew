'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState, useEffect } from 'react';
import { Save } from 'lucide-react';

export default function SettingsPage() {
  const queryClient = useQueryClient();
  const [settings, setSettings] = useState<Record<string, string>>({});

  const { data } = useQuery({
    queryKey: ['admin', 'settings'],
    queryFn: () => adminApi.settings(),
  });

  useEffect(() => {
    if (data?.data) setSettings(data.data);
  }, [data]);

  const updateSetting = useMutation({
    mutationFn: ({ key, value }: { key: string; value: string }) =>
      adminApi.updateSetting(key, value),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'settings'] }),
  });

  const settingsList = [
    { key: 'platform_name', label: 'Platform Name' },
    { key: 'map_provider', label: 'Map Provider (osm/google)' },
    { key: 'commission_rate', label: 'Commission Rate (%)' },
    { key: 'taxi_commission_rate', label: 'Taxi Commission Rate (%)' },
    { key: 'currency', label: 'Currency' },
    { key: 'support_email', label: 'Support Email' },
    { key: 'support_phone', label: 'Support Phone' },
  ];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Platform Settings</h1>

      <div className="bg-white rounded-xl border p-6 space-y-4 max-w-2xl">
        {settingsList.map((s) => (
          <div key={s.key} className="flex items-center gap-4">
            <label className="w-48 text-sm font-medium text-gray-700">{s.label}</label>
            <input
              type="text"
              value={settings[s.key] || ''}
              onChange={(e) => setSettings({ ...settings, [s.key]: e.target.value })}
              className="flex-1 px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
            <button
              onClick={() => updateSetting.mutate({ key: s.key, value: settings[s.key] || '' })}
              className="bg-primary-500 text-white p-2 rounded-lg hover:bg-primary-600"
              title="Save"
            >
              <Save className="w-4 h-4" />
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
