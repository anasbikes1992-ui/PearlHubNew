<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StaysListing;
use Illuminate\Http\Request;

class StaysController extends Controller
{
    public function index(Request $request)
    {
        $query = StaysListing::approved()->active()->with('owner');

        if ($request->filled('location')) {
            $query->where('location', 'ilike', '%' . $request->location . '%');
        }
        if ($request->filled('stay_type')) {
            $query->where('stay_type', $request->stay_type);
        }
        if ($request->filled('min_price')) {
            $query->where('price_per_night', '>=', $request->min_price);
        }
        if ($request->filled('max_price')) {
            $query->where('price_per_night', '<=', $request->max_price);
        }
        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('title', 'ilike', '%' . $request->search . '%')
                  ->orWhere('description', 'ilike', '%' . $request->search . '%');
            });
        }

        return response()->json($query->latest()->paginate(15));
    }

    public function show(string $id)
    {
        $stay = StaysListing::with(['owner', 'reviews.user'])->findOrFail($id);

        return response()->json($stay);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'stay_type' => 'required|in:hotel,villa,apartment,guest_house,boutique,resort,hostel',
            'stars' => 'nullable|integer|min:1|max:5',
            'price_per_night' => 'required|numeric|min:0',
            'location' => 'required|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'rooms' => 'nullable|integer|min:1',
            'amenities' => 'nullable|array',
            'images' => 'nullable|array',
        ]);

        $data['user_id'] = $request->user()->id;
        $data['moderation_status'] = 'pending';

        $stay = StaysListing::create($data);

        return response()->json($stay, 201);
    }

    public function update(Request $request, string $id)
    {
        $stay = StaysListing::where('user_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'stay_type' => 'nullable|in:hotel,villa,apartment,guest_house,boutique,resort,hostel',
            'stars' => 'nullable|integer|min:1|max:5',
            'price_per_night' => 'nullable|numeric|min:0',
            'location' => 'nullable|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'rooms' => 'nullable|integer|min:1',
            'amenities' => 'nullable|array',
            'images' => 'nullable|array',
        ]);

        $stay->update($data);

        return response()->json($stay->fresh());
    }

    public function destroy(Request $request, string $id)
    {
        $stay = StaysListing::where('user_id', $request->user()->id)->findOrFail($id);
        $stay->update(['active' => false]);

        return response()->json(['message' => 'Listing deactivated.']);
    }

    public function myListings(Request $request)
    {
        $listings = StaysListing::where('user_id', $request->user()->id)
            ->latest()
            ->paginate(15);

        return response()->json($listings);
    }
}
