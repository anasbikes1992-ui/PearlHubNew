<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EventsListing;
use Illuminate\Http\Request;

class EventsController extends Controller
{
    public function index(Request $request)
    {
        $query = EventsListing::where('moderation_status', 'approved')
            ->where('active', true)
            ->with('owner');

        if ($request->filled('location')) {
            $query->where('location', 'ilike', '%' . $request->location . '%');
        }
        if ($request->filled('event_type')) {
            $query->where('event_type', $request->event_type);
        }
        if ($request->filled('date_from')) {
            $query->where('event_date', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->where('event_date', '<=', $request->date_to);
        }
        if ($request->filled('search')) {
            $query->where('title', 'ilike', '%' . $request->search . '%');
        }

        return response()->json($query->latest()->paginate(15));
    }

    public function show(string $id)
    {
        return response()->json(
            EventsListing::with(['owner', 'reviews.user'])->findOrFail($id)
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'event_type' => 'required|in:cultural,adventure,food,wellness,nature,nightlife,sports,workshop',
            'price' => 'nullable|numeric|min:0',
            'location' => 'required|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'event_date' => 'nullable|date',
            'max_participants' => 'nullable|integer|min:1',
            'images' => 'nullable|array',
        ]);

        $data['user_id'] = $request->user()->id;
        $data['moderation_status'] = 'pending';

        return response()->json(EventsListing::create($data), 201);
    }

    public function update(Request $request, string $id)
    {
        $event = EventsListing::where('user_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'event_type' => 'nullable|in:cultural,adventure,food,wellness,nature,nightlife,sports,workshop',
            'price' => 'nullable|numeric|min:0',
            'location' => 'nullable|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'event_date' => 'nullable|date',
            'max_participants' => 'nullable|integer|min:1',
            'images' => 'nullable|array',
        ]);

        $event->update($data);

        return response()->json($event->fresh());
    }

    public function destroy(Request $request, string $id)
    {
        $event = EventsListing::where('user_id', $request->user()->id)->findOrFail($id);
        $event->update(['active' => false]);

        return response()->json(['message' => 'Listing deactivated.']);
    }

    public function myListings(Request $request)
    {
        return response()->json(
            EventsListing::where('user_id', $request->user()->id)->latest()->paginate(15)
        );
    }
}
