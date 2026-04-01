<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AdminAction;
use App\Models\Booking;
use App\Models\Earning;
use App\Models\EventsListing;
use App\Models\PlatformSetting;
use App\Models\Profile;
use App\Models\PropertiesListing;
use App\Models\SmeBusiness;
use App\Models\StaysListing;
use App\Models\TaxiKycDocument;
use App\Models\TaxiRide;
use App\Models\VehiclesListing;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function overview()
    {
        return response()->json([
            'total_users' => Profile::count(),
            'total_stays' => StaysListing::count(),
            'total_vehicles' => VehiclesListing::count(),
            'total_events' => EventsListing::count(),
            'total_properties' => PropertiesListing::count(),
            'total_sme' => SmeBusiness::count(),
            'total_bookings' => Booking::count(),
            'total_revenue' => round(Earning::sum('commission'), 2),
            'pending_moderation' => StaysListing::pending()->count()
                + VehiclesListing::where('moderation_status', 'pending')->count()
                + EventsListing::where('moderation_status', 'pending')->count()
                + PropertiesListing::where('moderation_status', 'pending')->count()
                + SmeBusiness::where('moderation_status', 'pending')->count(),
            'users_by_role' => Profile::selectRaw('role, count(*) as count')->groupBy('role')->pluck('count', 'role'),
        ]);
    }

    public function pendingListings()
    {
        return response()->json([
            'stays' => StaysListing::pending()->with('owner')->get(),
            'vehicles' => VehiclesListing::where('moderation_status', 'pending')->with('owner')->get(),
            'events' => EventsListing::where('moderation_status', 'pending')->with('owner')->get(),
            'properties' => PropertiesListing::where('moderation_status', 'pending')->with('owner')->get(),
            'sme' => SmeBusiness::where('moderation_status', 'pending')->with('owner')->get(),
        ]);
    }

    public function moderateListing(Request $request)
    {
        $data = $request->validate([
            'listing_type' => 'required|in:stay,vehicle,event,property,sme',
            'listing_id' => 'required|uuid',
            'status' => 'required|in:approved,rejected',
            'admin_note' => 'nullable|string',
        ]);

        $modelMap = [
            'stay' => StaysListing::class,
            'vehicle' => VehiclesListing::class,
            'event' => EventsListing::class,
            'property' => PropertiesListing::class,
            'sme' => SmeBusiness::class,
        ];

        $model = $modelMap[$data['listing_type']]::findOrFail($data['listing_id']);
        $model->update([
            'moderation_status' => $data['status'],
            'approved' => $data['status'] === 'approved',
            'admin_note' => $data['admin_note'] ?? null,
        ]);

        AdminAction::create([
            'admin_id' => $request->user()->id,
            'action' => "moderate_{$data['listing_type']}_{$data['status']}",
            'target_table' => $data['listing_type'],
            'target_id' => $data['listing_id'],
            'note' => $data['admin_note'] ?? null,
        ]);

        return response()->json(['message' => 'Listing moderated.', 'listing' => $model->fresh()]);
    }

    public function users(Request $request)
    {
        $query = Profile::query();

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }
        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('full_name', 'ilike', '%' . $request->search . '%')
                  ->orWhere('email', 'ilike', '%' . $request->search . '%');
            });
        }

        return response()->json($query->latest()->paginate(20));
    }

    public function updateUserRole(Request $request, string $id)
    {
        $data = $request->validate([
            'role' => 'required|in:customer,stays_provider,vehicle_provider,event_organizer,property_owner,taxi_driver,sme_owner,admin',
        ]);

        $profile = Profile::findOrFail($id);
        $profile->update(['role' => $data['role']]);

        AdminAction::create([
            'admin_id' => $request->user()->id,
            'action' => 'update_user_role',
            'target_table' => 'profiles',
            'target_id' => $id,
            'note' => "Role changed to {$data['role']}",
        ]);

        return response()->json($profile->fresh());
    }

    public function platformSettings()
    {
        return response()->json(PlatformSetting::all()->pluck('value', 'key'));
    }

    public function updatePlatformSetting(Request $request)
    {
        $data = $request->validate([
            'key' => 'required|string',
            'value' => 'required|string',
        ]);

        PlatformSetting::setValue($data['key'], $data['value']);

        AdminAction::create([
            'admin_id' => $request->user()->id,
            'action' => 'update_setting',
            'target_table' => 'platform_settings',
            'target_id' => $data['key'],
            'note' => "Set {$data['key']} = {$data['value']}",
        ]);

        return response()->json(['message' => 'Setting updated.']);
    }

    public function taxiStats()
    {
        return response()->json([
            'total_rides' => TaxiRide::count(),
            'completed_rides' => TaxiRide::where('status', 'completed')->count(),
            'active_rides' => TaxiRide::whereNotIn('status', ['completed', 'cancelled'])->count(),
            'total_fare' => round(TaxiRide::where('status', 'completed')->sum('fare'), 2),
            'avg_fare' => round(TaxiRide::where('status', 'completed')->avg('fare'), 2),
            'avg_rating' => round(TaxiRide::whereNotNull('rating')->avg('rating'), 2),
            'pending_kyc' => TaxiKycDocument::where('status', 'pending')->count(),
        ]);
    }

    public function kycReview()
    {
        return response()->json(
            TaxiKycDocument::where('status', 'pending')->with('driver')->get()
        );
    }

    public function approveKyc(Request $request, string $id)
    {
        $kyc = TaxiKycDocument::findOrFail($id);
        $kyc->update(['status' => 'approved']);

        AdminAction::create([
            'admin_id' => $request->user()->id,
            'action' => 'approve_kyc',
            'target_table' => 'taxi_kyc_documents',
            'target_id' => $id,
        ]);

        return response()->json(['message' => 'KYC approved.', 'kyc' => $kyc->fresh()]);
    }

    public function rejectKyc(Request $request, string $id)
    {
        $data = $request->validate(['note' => 'nullable|string']);

        $kyc = TaxiKycDocument::findOrFail($id);
        $kyc->update([
            'status' => 'rejected',
            'admin_note' => $data['note'] ?? null,
        ]);

        AdminAction::create([
            'admin_id' => $request->user()->id,
            'action' => 'reject_kyc',
            'target_table' => 'taxi_kyc_documents',
            'target_id' => $id,
            'note' => $data['note'] ?? null,
        ]);

        return response()->json(['message' => 'KYC rejected.', 'kyc' => $kyc->fresh()]);
    }

    public function adminActions(Request $request)
    {
        return response()->json(
            AdminAction::with('admin')->latest()->paginate(20)
        );
    }
}
