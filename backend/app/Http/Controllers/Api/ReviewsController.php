<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Review;
use Illuminate\Http\Request;

class ReviewsController extends Controller
{
    public function index(Request $request)
    {
        $request->validate([
            'listing_id' => 'required|uuid',
            'listing_type' => 'required|string',
        ]);

        return response()->json(
            Review::where('listing_id', $request->listing_id)
                ->where('listing_type', $request->listing_type)
                ->with('user')
                ->latest()
                ->paginate(15)
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'listing_id' => 'required|uuid',
            'listing_type' => 'required|string',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string',
        ]);

        $data['user_id'] = $request->user()->id;

        $review = Review::create($data);

        return response()->json($review->load('user'), 201);
    }

    public function destroy(Request $request, string $id)
    {
        Review::where('user_id', $request->user()->id)->findOrFail($id)->delete();

        return response()->json(['message' => 'Review deleted.']);
    }
}
