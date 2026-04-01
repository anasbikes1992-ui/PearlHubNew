<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TaxiDriverLocation;
use App\Models\TaxiPromoCode;
use App\Models\TaxiRide;
use App\Models\TaxiVehicleCategory;
use Illuminate\Http\Request;

class TaxiController extends Controller
{
    public function requestRide(Request $request)
    {
        $data = $request->validate([
            'vehicle_category_slug' => 'required|string',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'pickup_address' => 'nullable|string',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
            'dropoff_address' => 'nullable|string',
            'is_parcel' => 'nullable|boolean',
            'parcel_details' => 'nullable|array',
            'stops' => 'nullable|array',
            'payment_method' => 'nullable|string',
            'promo_code' => 'nullable|string',
            'scheduled_for' => 'nullable|date',
        ]);

        $category = TaxiVehicleCategory::where('slug', $data['vehicle_category_slug'])->firstOrFail();

        $distance = $this->haversineDistance(
            $data['pickup_lat'], $data['pickup_lng'],
            $data['dropoff_lat'], $data['dropoff_lng']
        );

        $fare = $category->base_fare + ($distance * $category->per_km_rate);

        if (!empty($data['promo_code'])) {
            $promo = TaxiPromoCode::where('code', $data['promo_code'])
                ->where('active', true)
                ->where('valid_from', '<=', now())
                ->where('valid_until', '>=', now())
                ->first();

            if ($promo && $fare >= $promo->min_fare) {
                $discount = $fare * ($promo->discount_percent / 100);
                if ($promo->max_discount) {
                    $discount = min($discount, $promo->max_discount);
                }
                $fare = max(0, $fare - $discount);
            }
        }

        $ride = TaxiRide::create([
            'rider_id' => $request->user()->id,
            'vehicle_category_id' => $category->id,
            'vehicle_category_slug' => $category->slug,
            'pickup_lat' => $data['pickup_lat'],
            'pickup_lng' => $data['pickup_lng'],
            'pickup_address' => $data['pickup_address'] ?? null,
            'dropoff_lat' => $data['dropoff_lat'],
            'dropoff_lng' => $data['dropoff_lng'],
            'dropoff_address' => $data['dropoff_address'] ?? null,
            'fare' => round($fare, 2),
            'distance_km' => round($distance, 2),
            'status' => 'requested',
            'is_parcel' => $data['is_parcel'] ?? false,
            'parcel_details' => $data['parcel_details'] ?? null,
            'stops' => $data['stops'] ?? null,
            'payment_method' => $data['payment_method'] ?? 'cash',
            'promo_code' => $data['promo_code'] ?? null,
            'scheduled_for' => $data['scheduled_for'] ?? null,
        ]);

        return response()->json($ride->load('vehicleCategory'), 201);
    }

    public function activeRide(Request $request)
    {
        $ride = TaxiRide::where('rider_id', $request->user()->id)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->with(['driver', 'vehicleCategory', 'chatMessages'])
            ->latest()
            ->first();

        return response()->json($ride);
    }

    public function rideHistory(Request $request)
    {
        return response()->json(
            TaxiRide::where('rider_id', $request->user()->id)
                ->with(['driver', 'vehicleCategory'])
                ->latest()
                ->paginate(15)
        );
    }

    public function cancelRide(Request $request, string $id)
    {
        $ride = TaxiRide::where('rider_id', $request->user()->id)
            ->whereIn('status', ['requested', 'accepted'])
            ->findOrFail($id);

        $ride->update(['status' => 'cancelled']);

        return response()->json(['message' => 'Ride cancelled.', 'ride' => $ride->fresh()]);
    }

    public function rateRide(Request $request, string $id)
    {
        $ride = TaxiRide::where('rider_id', $request->user()->id)
            ->where('status', 'completed')
            ->findOrFail($id);

        $data = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'rating_comment' => 'nullable|string',
        ]);

        $ride->update($data);

        return response()->json($ride->fresh());
    }

    public function nearbyDrivers(Request $request)
    {
        $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'radius_km' => 'nullable|numeric|min:0.5|max:50',
        ]);

        $lat = $request->lat;
        $lng = $request->lng;
        $radius = $request->radius_km ?? 10;

        $drivers = TaxiDriverLocation::where('is_online', true)
            ->selectRaw("*, (
                6371 * acos(
                    cos(radians(?)) * cos(radians(lat)) *
                    cos(radians(lng) - radians(?)) +
                    sin(radians(?)) * sin(radians(lat))
                )
            ) AS distance_km", [$lat, $lng, $lat])
            ->having('distance_km', '<=', $radius)
            ->orderBy('distance_km')
            ->limit(20)
            ->get();

        return response()->json($drivers);
    }

    public function applyPromo(Request $request)
    {
        $data = $request->validate([
            'code' => 'required|string',
            'fare' => 'required|numeric|min:0',
        ]);

        $promo = TaxiPromoCode::where('code', $data['code'])
            ->where('active', true)
            ->where('valid_from', '<=', now())
            ->where('valid_until', '>=', now())
            ->first();

        if (!$promo) {
            return response()->json(['valid' => false, 'message' => 'Invalid or expired promo code.']);
        }

        if ($promo->max_uses && $promo->used_count >= $promo->max_uses) {
            return response()->json(['valid' => false, 'message' => 'Promo code usage limit reached.']);
        }

        if ($data['fare'] < $promo->min_fare) {
            return response()->json(['valid' => false, 'message' => "Minimum fare of LKR {$promo->min_fare} required."]);
        }

        $discount = $data['fare'] * ($promo->discount_percent / 100);
        if ($promo->max_discount) {
            $discount = min($discount, $promo->max_discount);
        }

        return response()->json([
            'valid' => true,
            'discount' => round($discount, 2),
            'new_fare' => round($data['fare'] - $discount, 2),
            'promo' => $promo,
        ]);
    }

    public function calculateFare(Request $request)
    {
        $data = $request->validate([
            'vehicle_category_slug' => 'required|string',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
        ]);

        $category = TaxiVehicleCategory::where('slug', $data['vehicle_category_slug'])->firstOrFail();

        $distance = $this->haversineDistance(
            $data['pickup_lat'], $data['pickup_lng'],
            $data['dropoff_lat'], $data['dropoff_lng']
        );

        $fare = $category->base_fare + ($distance * $category->per_km_rate);

        return response()->json([
            'fare' => round($fare, 2),
            'distance_km' => round($distance, 2),
            'category' => $category,
        ]);
    }

    private function haversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
