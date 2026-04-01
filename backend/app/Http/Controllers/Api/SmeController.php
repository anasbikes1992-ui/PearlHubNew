<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SmeBusiness;
use App\Models\SmeProduct;
use Illuminate\Http\Request;

class SmeController extends Controller
{
    public function index(Request $request)
    {
        $query = SmeBusiness::where('moderation_status', 'approved')
            ->where('active', true);

        if ($request->filled('business_type')) {
            $query->where('business_type', $request->business_type);
        }
        if ($request->filled('location')) {
            $query->where('location', 'ilike', '%' . $request->location . '%');
        }
        if ($request->filled('search')) {
            $query->where('business_name', 'ilike', '%' . $request->search . '%');
        }

        return response()->json($query->latest()->paginate(15));
    }

    public function show(string $id)
    {
        return response()->json(
            SmeBusiness::with(['owner', 'products'])->findOrFail($id)
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'business_name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'business_type' => 'required|in:restaurant,shop,service,craft,tour_operator,other',
            'location' => 'required|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'phone' => 'nullable|string',
            'website' => 'nullable|string',
            'logo_url' => 'nullable|string',
            'images' => 'nullable|array',
        ]);

        $data['user_id'] = $request->user()->id;
        $data['moderation_status'] = 'pending';

        return response()->json(SmeBusiness::create($data), 201);
    }

    public function update(Request $request, string $id)
    {
        $biz = SmeBusiness::where('user_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'business_name' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'business_type' => 'nullable|in:restaurant,shop,service,craft,tour_operator,other',
            'location' => 'nullable|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'phone' => 'nullable|string',
            'website' => 'nullable|string',
            'logo_url' => 'nullable|string',
            'images' => 'nullable|array',
        ]);

        $biz->update($data);

        return response()->json($biz->fresh());
    }

    public function destroy(Request $request, string $id)
    {
        $biz = SmeBusiness::where('user_id', $request->user()->id)->findOrFail($id);
        $biz->update(['active' => false]);

        return response()->json(['message' => 'Business deactivated.']);
    }

    public function myListings(Request $request)
    {
        return response()->json(
            SmeBusiness::where('user_id', $request->user()->id)->latest()->paginate(15)
        );
    }

    public function products(string $id)
    {
        $business = SmeBusiness::findOrFail($id);

        return response()->json($business->products()->where('available', true)->get());
    }

    public function storeProduct(Request $request, string $id)
    {
        SmeBusiness::where('user_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'image_url' => 'nullable|string',
        ]);

        $data['business_id'] = $id;

        return response()->json(SmeProduct::create($data), 201);
    }

    public function updateProduct(Request $request, string $businessId, string $productId)
    {
        SmeBusiness::where('user_id', $request->user()->id)->findOrFail($businessId);
        $product = SmeProduct::where('business_id', $businessId)->findOrFail($productId);

        $data = $request->validate([
            'name' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'price' => 'nullable|numeric|min:0',
            'image_url' => 'nullable|string',
            'available' => 'nullable|boolean',
        ]);

        $product->update($data);

        return response()->json($product->fresh());
    }

    public function deleteProduct(Request $request, string $businessId, string $productId)
    {
        SmeBusiness::where('user_id', $request->user()->id)->findOrFail($businessId);
        SmeProduct::where('business_id', $businessId)->findOrFail($productId)->delete();

        return response()->json(['message' => 'Product deleted.']);
    }
}
