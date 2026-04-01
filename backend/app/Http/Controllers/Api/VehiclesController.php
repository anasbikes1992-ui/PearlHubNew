<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VehiclesListing;
use Illuminate\Http\Request;

class VehiclesController extends Controller
{
    public function index(Request $request)
    {
        $query = VehiclesListing::where('moderation_status', 'approved')
            ->where('active', true)
            ->with('owner');

        if ($request->filled('location')) {
            $query->where('location', 'ilike', '%' . $request->location . '%');
        }
        if ($request->filled('vehicle_type')) {
            $query->where('vehicle_type', $request->vehicle_type);
        }
        if ($request->filled('min_price')) {
            $query->where('price_per_day', '>=', $request->min_price);
        }
        if ($request->filled('max_price')) {
            $query->where('price_per_day', '<=', $request->max_price);
        }
        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('title', 'ilike', '%' . $request->search . '%')
                  ->orWhere('brand', 'ilike', '%' . $request->search . '%');
            });
        }

        return response()->json($query->latest()->paginate(15));
    }

    public function show(string $id)
    {
        return response()->json(
            VehiclesListing::with(['owner', 'reviews.user'])->findOrFail($id)
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'vehicle_type' => 'required|in:car,van,suv,bus,motorcycle,tuk_tuk,bicycle',
            'brand' => 'nullable|string',
            'model' => 'nullable|string',
            'year' => 'nullable|integer',
            'price_per_day' => 'required|numeric|min:0',
            'location' => 'required|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'features' => 'nullable|array',
            'images' => 'nullable|array',
        ]);

        $data['user_id'] = $request->user()->id;
        $data['moderation_status'] = 'pending';

        return response()->json(VehiclesListing::create($data), 201);
    }

    public function update(Request $request, string $id)
    {
        $vehicle = VehiclesListing::where('user_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'vehicle_type' => 'nullable|in:car,van,suv,bus,motorcycle,tuk_tuk,bicycle',
            'brand' => 'nullable|string',
            'model' => 'nullable|string',
            'year' => 'nullable|integer',
            'price_per_day' => 'nullable|numeric|min:0',
            'location' => 'nullable|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'features' => 'nullable|array',
            'images' => 'nullable|array',
        ]);

        $vehicle->update($data);

        return response()->json($vehicle->fresh());
    }

    public function destroy(Request $request, string $id)
    {
        $vehicle = VehiclesListing::where('user_id', $request->user()->id)->findOrFail($id);
        $vehicle->update(['active' => false]);

        return response()->json(['message' => 'Listing deactivated.']);
    }

    public function myListings(Request $request)
    {
        return response()->json(
            VehiclesListing::where('user_id', $request->user()->id)->latest()->paginate(15)
        );
    }
}
