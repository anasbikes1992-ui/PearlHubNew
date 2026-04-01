<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Earning;
use Illuminate\Http\Request;

class BookingsController extends Controller
{
    public function index(Request $request)
    {
        return response()->json(
            Booking::where('user_id', $request->user()->id)
                ->with('provider')
                ->latest()
                ->paginate(15)
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'listing_id' => 'required|uuid',
            'listing_type' => 'required|in:stay,vehicle,event,property',
            'provider_id' => 'nullable|uuid',
            'check_in' => 'nullable|date',
            'check_out' => 'nullable|date|after_or_equal:check_in',
            'guests' => 'nullable|integer|min:1',
            'total_price' => 'required|numeric|min:0',
            'payment_method' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $data['user_id'] = $request->user()->id;
        $data['status'] = 'pending';
        $data['payment_status'] = 'pending';

        $booking = Booking::create($data);

        return response()->json($booking, 201);
    }

    public function show(Request $request, string $id)
    {
        $booking = Booking::where('user_id', $request->user()->id)
            ->with(['provider', 'earning'])
            ->findOrFail($id);

        return response()->json($booking);
    }

    public function cancel(Request $request, string $id)
    {
        $booking = Booking::where('user_id', $request->user()->id)
            ->whereIn('status', ['pending', 'confirmed'])
            ->findOrFail($id);

        $booking->update([
            'status' => 'cancelled',
            'payment_status' => $booking->payment_status === 'completed' ? 'refunded' : 'failed',
        ]);

        return response()->json(['message' => 'Booking cancelled.', 'booking' => $booking->fresh()]);
    }

    public function providerBookings(Request $request)
    {
        return response()->json(
            Booking::where('provider_id', $request->user()->id)
                ->with('user')
                ->latest()
                ->paginate(15)
        );
    }

    public function updateStatus(Request $request, string $id)
    {
        $booking = Booking::where('provider_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'status' => 'required|in:confirmed,cancelled,completed',
        ]);

        $booking->update(['status' => $data['status']]);

        if ($data['status'] === 'completed' && $booking->payment_status === 'completed') {
            $commission = $booking->total_price * 0.10;
            Earning::create([
                'provider_id' => $request->user()->id,
                'booking_id' => $booking->id,
                'amount' => $booking->total_price - $commission,
                'commission' => $commission,
                'status' => 'pending',
            ]);
        }

        return response()->json($booking->fresh());
    }
}
