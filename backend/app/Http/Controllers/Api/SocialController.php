<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SocialPost;
use Illuminate\Http\Request;

class SocialController extends Controller
{
    public function feed(Request $request)
    {
        return response()->json(
            SocialPost::with('user')->latest()->paginate(20)
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'content' => 'required|string|max:2000',
            'images' => 'nullable|array',
        ]);

        $data['user_id'] = $request->user()->id;

        $post = SocialPost::create($data);

        return response()->json($post->load('user'), 201);
    }

    public function like(Request $request, string $id)
    {
        $post = SocialPost::findOrFail($id);
        $post->increment('likes_count');

        return response()->json($post->fresh());
    }

    public function destroy(Request $request, string $id)
    {
        SocialPost::where('user_id', $request->user()->id)->findOrFail($id)->delete();

        return response()->json(['message' => 'Post deleted.']);
    }
}
