<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PropertiesListing;
use Illuminate\Http\Request;

class PropertiesController extends Controller
{
    public function index(Request $request)
    {
        $query = PropertiesListing::where('moderation_status', 'approved')
            ->where('active', true)
            ->with('owner');

        if ($request->filled('location')) {
            $query->where('location', 'ilike', '%' . $request->location . '%');
        }
        if ($request->filled('property_type')) {
            $query->where('property_type', $request->property_type);
        }
        if ($request->filled('listing_type')) {
            $query->where('listing_type', $request->listing_type);
        }
        if ($request->filled('min_price')) {
            $query->where('price', '>=', $request->min_price);
        }
        if ($request->filled('max_price')) {
            $query->where('price', '<=', $request->max_price);
        }
        if ($request->filled('bedrooms')) {
            $query->where('bedrooms', '>=', $request->bedrooms);
        }
        if ($request->filled('search')) {
            $query->where('title', 'ilike', '%' . $request->search . '%');
        }

        return response()->json($query->latest()->paginate(15));
    }

    public function show(string $id)
    {
        return response()->json(
            PropertiesListing::with(['owner', 'reviews.user'])->findOrFail($id)
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'property_type' => 'required|in:house,apartment,land,commercial,villa',
            'listing_type' => 'required|in:sale,rent',
            'price' => 'required|numeric|min:0',
            'location' => 'required|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'bedrooms' => 'nullable|integer',
            'bathrooms' => 'nullable|integer',
            'area_sqft' => 'nullable|numeric',
            'features' => 'nullable|array',
            'images' => 'nullable|array',
        ]);

        $data['user_id'] = $request->user()->id;
        $data['moderation_status'] = 'pending';

        return response()->json(PropertiesListing::create($data), 201);
    }

    public function update(Request $request, string $id)
    {
        $property = PropertiesListing::where('user_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'property_type' => 'nullable|in:house,apartment,land,commercial,villa',
            'listing_type' => 'nullable|in:sale,rent',
            'price' => 'nullable|numeric|min:0',
            'location' => 'nullable|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'bedrooms' => 'nullable|integer',
            'bathrooms' => 'nullable|integer',
            'area_sqft' => 'nullable|numeric',
            'features' => 'nullable|array',
            'images' => 'nullable|array',
        ]);

        $property->update($data);

        return response()->json($property->fresh());
    }

    public function destroy(Request $request, string $id)
    {
        $property = PropertiesListing::where('user_id', $request->user()->id)->findOrFail($id);
        $property->update(['active' => false]);

        return response()->json(['message' => 'Listing deactivated.']);
    }

    public function myListings(Request $request)
    {
        return response()->json(
            PropertiesListing::where('user_id', $request->user()->id)->latest()->paginate(15)
        );
    }
}
