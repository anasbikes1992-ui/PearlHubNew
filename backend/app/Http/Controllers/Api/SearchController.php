<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EventsListing;
use App\Models\PropertiesListing;
use App\Models\SmeBusiness;
use App\Models\StaysListing;
use App\Models\VehiclesListing;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function global(Request $request)
    {
        $request->validate(['q' => 'required|string|min:2']);
        $q = $request->q;
        $limit = 5;

        return response()->json([
            'stays' => StaysListing::approved()->active()
                ->where('title', 'ilike', "%{$q}%")
                ->limit($limit)->get(),
            'vehicles' => VehiclesListing::where('moderation_status', 'approved')->where('active', true)
                ->where('title', 'ilike', "%{$q}%")
                ->limit($limit)->get(),
            'events' => EventsListing::where('moderation_status', 'approved')->where('active', true)
                ->where('title', 'ilike', "%{$q}%")
                ->limit($limit)->get(),
            'properties' => PropertiesListing::where('moderation_status', 'approved')->where('active', true)
                ->where('title', 'ilike', "%{$q}%")
                ->limit($limit)->get(),
            'sme' => SmeBusiness::where('moderation_status', 'approved')->where('active', true)
                ->where('business_name', 'ilike', "%{$q}%")
                ->limit($limit)->get(),
        ]);
    }
}
