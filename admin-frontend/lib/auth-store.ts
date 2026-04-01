import { create } from 'zustand';
import { authApi } from './api';

interface User {
  id: string;
  name: string;
  email: string;
  profile: {
    id: string;
    full_name: string;
    email: string;
    phone: string | null;
    role: string;
    avatar_url: string | null;
    verified: boolean;
    provider_tier: string;
    preferred_language: string;
  };
}

interface AuthState {
  user: User | null;
  token: string | null;
  loading: boolean;
  setAuth: (user: User, token: string) => void;
  logout: () => void;
  fetchUser: () => Promise<void>;
  isProvider: () => boolean;
  isAdmin: () => boolean;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: typeof window !== 'undefined' ? localStorage.getItem('pearlhub_token') : null,
  loading: true,

  setAuth: (user, token) => {
    localStorage.setItem('pearlhub_token', token);
    set({ user, token, loading: false });
  },

  logout: () => {
    localStorage.removeItem('pearlhub_token');
    set({ user: null, token: null, loading: false });
    authApi.logout().catch(() => {});
  },

  fetchUser: async () => {
    const token = localStorage.getItem('pearlhub_token');
    if (!token) {
      set({ loading: false });
      return;
    }
    try {
      const { data } = await authApi.me();
      set({ user: data.user, token, loading: false });
    } catch {
      localStorage.removeItem('pearlhub_token');
      set({ user: null, token: null, loading: false });
    }
  },

  isProvider: () => {
    const role = get().user?.profile?.role;
    return ['stays_provider', 'vehicle_provider', 'event_organizer', 'property_owner', 'sme_owner', 'taxi_driver'].includes(role || '');
  },

  isAdmin: () => get().user?.profile?.role === 'admin',
}));
