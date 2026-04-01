<?php

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AiConciergeController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingsController;
use App\Http\Controllers\Api\EventsController;
use App\Http\Controllers\Api\PropertiesController;
use App\Http\Controllers\Api\ReviewsController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\SmeController;
use App\Http\Controllers\Api\SocialController;
use App\Http\Controllers\Api\StaysController;
use App\Http\Controllers\Api\TaxiController;
use App\Http\Controllers\Api\TaxiDriverController;
use App\Http\Controllers\Api\VehiclesController;
use App\Http\Controllers\Api\WalletController;
use App\Models\RecentlyViewed;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Public auth
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);

// Public listings
Route::get('/stays', [StaysController::class, 'index']);
Route::get('/stays/{id}', [StaysController::class, 'show']);
Route::get('/vehicles', [VehiclesController::class, 'index']);
Route::get('/vehicles/{id}', [VehiclesController::class, 'show']);
Route::get('/events', [EventsController::class, 'index']);
Route::get('/events/{id}', [EventsController::class, 'show']);
Route::get('/properties', [PropertiesController::class, 'index']);
Route::get('/properties/{id}', [PropertiesController::class, 'show']);
Route::get('/sme', [SmeController::class, 'index']);
Route::get('/sme/{id}', [SmeController::class, 'show']);
Route::get('/sme/{id}/products', [SmeController::class, 'products']);
Route::get('/search', [SearchController::class, 'global']);
Route::get('/reviews', [ReviewsController::class, 'index']);
Route::get('/social/feed', [SocialController::class, 'feed']);

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::put('/auth/profile', [AuthController::class, 'updateProfile']);

    // Bookings
    Route::get('/bookings', [BookingsController::class, 'index']);
    Route::post('/bookings', [BookingsController::class, 'store']);
    Route::get('/bookings/{id}', [BookingsController::class, 'show']);
    Route::post('/bookings/{id}/cancel', [BookingsController::class, 'cancel']);

    // Reviews
    Route::post('/reviews', [ReviewsController::class, 'store']);
    Route::delete('/reviews/{id}', [ReviewsController::class, 'destroy']);

    // Wallet
    Route::get('/wallet/balance', [WalletController::class, 'balance']);
    Route::get('/wallet/transactions', [WalletController::class, 'transactions']);
    Route::post('/wallet/deposit', [WalletController::class, 'deposit']);
    Route::post('/wallet/withdraw', [WalletController::class, 'withdraw']);

    // Taxi - Rider
    Route::post('/taxi/request', [TaxiController::class, 'requestRide']);
    Route::get('/taxi/active', [TaxiController::class, 'activeRide']);
    Route::get('/taxi/history', [TaxiController::class, 'rideHistory']);
    Route::post('/taxi/{id}/cancel', [TaxiController::class, 'cancelRide']);
    Route::post('/taxi/{id}/rate', [TaxiController::class, 'rateRide']);
    Route::get('/taxi/nearby-drivers', [TaxiController::class, 'nearbyDrivers']);
    Route::post('/taxi/apply-promo', [TaxiController::class, 'applyPromo']);
    Route::post('/taxi/calculate-fare', [TaxiController::class, 'calculateFare']);

    // Taxi - Driver
    Route::post('/taxi/driver/online', [TaxiDriverController::class, 'goOnline']);
    Route::post('/taxi/driver/offline', [TaxiDriverController::class, 'goOffline']);
    Route::post('/taxi/driver/location', [TaxiDriverController::class, 'updateLocation']);
    Route::post('/taxi/driver/accept/{id}', [TaxiDriverController::class, 'acceptRide']);
    Route::post('/taxi/driver/ride/{id}/status', [TaxiDriverController::class, 'updateRideStatus']);
    Route::post('/taxi/driver/kyc', [TaxiDriverController::class, 'kycSubmit']);
    Route::get('/taxi/driver/kyc-status', [TaxiDriverController::class, 'kycStatus']);
    Route::get('/taxi/driver/earnings', [TaxiDriverController::class, 'earnings']);

    // Social
    Route::post('/social', [SocialController::class, 'store']);
    Route::post('/social/{id}/like', [SocialController::class, 'like']);
    Route::delete('/social/{id}', [SocialController::class, 'destroy']);

    // AI Concierge
    Route::post('/ai/concierge', [AiConciergeController::class, 'query']);

    // Recently Viewed
    Route::get('/recently-viewed', function (Request $request) {
        return response()->json(
            RecentlyViewed::where('user_id', $request->user()->id)->latest()->limit(20)->get()
        );
    });

    // Provider routes
    Route::middleware('role:stays_provider,vehicle_provider,event_organizer,property_owner,sme_owner,taxi_driver,admin')->group(function () {
        Route::get('/provider/bookings', [BookingsController::class, 'providerBookings']);
        Route::put('/provider/bookings/{id}/status', [BookingsController::class, 'updateStatus']);

        Route::post('/stays', [StaysController::class, 'store']);
        Route::put('/stays/{id}', [StaysController::class, 'update']);
        Route::delete('/stays/{id}', [StaysController::class, 'destroy']);
        Route::get('/my/stays', [StaysController::class, 'myListings']);

        Route::post('/vehicles', [VehiclesController::class, 'store']);
        Route::put('/vehicles/{id}', [VehiclesController::class, 'update']);
        Route::delete('/vehicles/{id}', [VehiclesController::class, 'destroy']);
        Route::get('/my/vehicles', [VehiclesController::class, 'myListings']);

        Route::post('/events', [EventsController::class, 'store']);
        Route::put('/events/{id}', [EventsController::class, 'update']);
        Route::delete('/events/{id}', [EventsController::class, 'destroy']);
        Route::get('/my/events', [EventsController::class, 'myListings']);

        Route::post('/properties', [PropertiesController::class, 'store']);
        Route::put('/properties/{id}', [PropertiesController::class, 'update']);
        Route::delete('/properties/{id}', [PropertiesController::class, 'destroy']);
        Route::get('/my/properties', [PropertiesController::class, 'myListings']);

        Route::post('/sme', [SmeController::class, 'store']);
        Route::put('/sme/{id}', [SmeController::class, 'update']);
        Route::delete('/sme/{id}', [SmeController::class, 'destroy']);
        Route::get('/my/sme', [SmeController::class, 'myListings']);
        Route::post('/sme/{id}/products', [SmeController::class, 'storeProduct']);
        Route::put('/sme/{businessId}/products/{productId}', [SmeController::class, 'updateProduct']);
        Route::delete('/sme/{businessId}/products/{productId}', [SmeController::class, 'deleteProduct']);
    });

    // Admin routes
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/overview', [AdminController::class, 'overview']);
        Route::get('/pending-listings', [AdminController::class, 'pendingListings']);
        Route::post('/moderate-listing', [AdminController::class, 'moderateListing']);
        Route::get('/users', [AdminController::class, 'users']);
        Route::put('/users/{id}/role', [AdminController::class, 'updateUserRole']);
        Route::get('/settings', [AdminController::class, 'platformSettings']);
        Route::post('/settings', [AdminController::class, 'updatePlatformSetting']);
        Route::get('/taxi-stats', [AdminController::class, 'taxiStats']);
        Route::get('/kyc-review', [AdminController::class, 'kycReview']);
        Route::post('/kyc/{id}/approve', [AdminController::class, 'approveKyc']);
        Route::post('/kyc/{id}/reject', [AdminController::class, 'rejectKyc']);
        Route::get('/actions', [AdminController::class, 'adminActions']);
    });
});
