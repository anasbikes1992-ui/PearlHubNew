<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Earning;
use App\Models\TaxiDriverLocation;
use App\Models\TaxiKycDocument;
use App\Models\TaxiRide;
use Illuminate\Http\Request;

class TaxiDriverController extends Controller
{
    public function goOnline(Request $request)
    {
        $data = $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'vehicle_category' => 'nullable|string',
        ]);

        $location = TaxiDriverLocation::updateOrCreate(
            ['driver_id' => $request->user()->id],
            [
                'lat' => $data['lat'],
                'lng' => $data['lng'],
                'is_online' => true,
                'vehicle_category' => $data['vehicle_category'] ?? null,
                'updated_at' => now(),
            ]
        );

        return response()->json(['message' => 'You are now online.', 'location' => $location]);
    }

    public function goOffline(Request $request)
    {
        TaxiDriverLocation::where('driver_id', $request->user()->id)
            ->update(['is_online' => false, 'updated_at' => now()]);

        return response()->json(['message' => 'You are now offline.']);
    }

    public function updateLocation(Request $request)
    {
        $data = $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
        ]);

        TaxiDriverLocation::where('driver_id', $request->user()->id)
            ->update([
                'lat' => $data['lat'],
                'lng' => $data['lng'],
                'updated_at' => now(),
            ]);

        return response()->json(['message' => 'Location updated.']);
    }

    public function acceptRide(Request $request, string $id)
    {
        $ride = TaxiRide::where('status', 'requested')->findOrFail($id);

        $ride->update([
            'driver_id' => $request->user()->id,
            'status' => 'accepted',
        ]);

        return response()->json($ride->load(['rider', 'vehicleCategory']));
    }

    public function updateRideStatus(Request $request, string $id)
    {
        $ride = TaxiRide::where('driver_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'status' => 'required|in:arrived,in_progress,completed,cancelled',
        ]);

        $ride->update(['status' => $data['status']]);

        if ($data['status'] === 'completed') {
            $commission = $ride->fare * 0.15;
            Earning::create([
                'provider_id' => $request->user()->id,
                'booking_id' => $ride->id,
                'amount' => $ride->fare - $commission,
                'commission' => $commission,
                'status' => 'pending',
            ]);
        }

        return response()->json($ride->fresh());
    }

    public function kycSubmit(Request $request)
    {
        $data = $request->validate([
            'license_number' => 'required|string',
            'license_expiry' => 'required|date',
            'vehicle_registration' => 'required|string',
            'vehicle_type' => 'required|string',
            'insurance_number' => 'nullable|string',
            'insurance_expiry' => 'nullable|date',
            'nic_front_url' => 'nullable|string',
            'nic_back_url' => 'nullable|string',
            'license_front_url' => 'nullable|string',
        ]);

        $data['driver_id'] = $request->user()->id;
        $data['status'] = 'pending';

        $kyc = TaxiKycDocument::updateOrCreate(
            ['driver_id' => $request->user()->id],
            $data
        );

        return response()->json($kyc, 201);
    }

    public function kycStatus(Request $request)
    {
        $kyc = TaxiKycDocument::where('driver_id', $request->user()->id)->first();

        return response()->json($kyc);
    }

    public function earnings(Request $request)
    {
        $earnings = Earning::where('provider_id', $request->user()->id);

        $total = (clone $earnings)->sum('amount');
        $pending = (clone $earnings)->where('status', 'pending')->sum('amount');
        $released = (clone $earnings)->where('status', 'released')->sum('amount');

        $rides = TaxiRide::where('driver_id', $request->user()->id)
            ->where('status', 'completed');

        return response()->json([
            'total_earnings' => round($total, 2),
            'pending_earnings' => round($pending, 2),
            'released_earnings' => round($released, 2),
            'total_rides' => $rides->count(),
            'recent_earnings' => Earning::where('provider_id', $request->user()->id)
                ->latest()
                ->limit(10)
                ->get(),
        ]);
    }
}
