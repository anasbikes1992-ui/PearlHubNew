'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { socialApi } from '@/lib/api';
import { useAuthStore } from '@/lib/auth-store';
import { formatDate } from '@/lib/utils';
import { Heart, Trash2 } from 'lucide-react';
import { useState } from 'react';

export default function SocialPage() {
  const user = useAuthStore((s) => s.user);
  const queryClient = useQueryClient();
  const [content, setContent] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['social', 'feed'],
    queryFn: () => socialApi.feed(),
  });

  const createPost = useMutation({
    mutationFn: () => socialApi.create({ content }),
    onSuccess: () => {
      setContent('');
      queryClient.invalidateQueries({ queryKey: ['social'] });
    },
  });

  const likePost = useMutation({
    mutationFn: (id: string) => socialApi.like(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['social'] }),
  });

  const deletePost = useMutation({
    mutationFn: (id: string) => socialApi.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['social'] }),
  });

  const posts = data?.data?.data || [];

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Community</h1>

      {user && (
        <div className="bg-white rounded-xl border p-4 mb-6">
          <textarea
            placeholder="Share your Sri Lanka experience..."
            value={content}
            onChange={(e) => setContent(e.target.value)}
            rows={3}
            className="w-full px-3 py-2 border rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
          <div className="flex justify-end mt-2">
            <button
              onClick={() => createPost.mutate()}
              disabled={!content.trim() || createPost.isPending}
              className="bg-primary-500 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-primary-600 disabled:opacity-50"
            >
              Post
            </button>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => <div key={i} className="bg-gray-100 rounded-xl h-32 animate-pulse" />)}
        </div>
      ) : (
        <div className="space-y-4">
          {posts.map((post: Record<string, unknown>) => (
            <div key={post.id as string} className="bg-white rounded-xl border p-5">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-9 h-9 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-bold text-sm">
                  {((post.user as Record<string, string>)?.full_name?.[0]) || 'U'}
                </div>
                <div>
                  <p className="font-medium text-sm">{(post.user as Record<string, string>)?.full_name || 'User'}</p>
                  <p className="text-xs text-gray-400">{formatDate(post.created_at as string)}</p>
                </div>
              </div>
              <p className="text-gray-700 whitespace-pre-wrap">{post.content as string}</p>
              <div className="flex items-center gap-4 mt-3 pt-3 border-t">
                <button
                  onClick={() => likePost.mutate(post.id as string)}
                  className="flex items-center gap-1 text-sm text-gray-500 hover:text-red-500 transition-colors"
                >
                  <Heart className="w-4 h-4" />
                  <span>{(post.likes_count as number) || 0}</span>
                </button>
                {user && user.id === (post.user as Record<string, string>)?.id && (
                  <button
                    onClick={() => deletePost.mutate(post.id as string)}
                    className="text-sm text-gray-400 hover:text-red-500 transition-colors ml-auto"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
