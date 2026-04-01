<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TaxiRide extends Model
{
    use HasUuid;

    protected $fillable = [
        'rider_id',
        'driver_id',
        'vehicle_category_id',
        'vehicle_category_slug',
        'pickup_lat',
        'pickup_lng',
        'pickup_address',
        'dropoff_lat',
        'dropoff_lng',
        'dropoff_address',
        'fare',
        'distance_km',
        'duration_minutes',
        'status',
        'is_parcel',
        'parcel_details',
        'stops',
        'payment_method',
        'payment_status',
        'surge_multiplier',
        'scheduled_for',
        'promo_code',
        'rating',
        'rating_comment',
        'is_emergency_sos',
    ];

    protected function casts(): array
    {
        return [
            'pickup_lat' => 'decimal:8',
            'pickup_lng' => 'decimal:8',
            'dropoff_lat' => 'decimal:8',
            'dropoff_lng' => 'decimal:8',
            'fare' => 'decimal:2',
            'distance_km' => 'decimal:2',
            'duration_minutes' => 'integer',
            'is_parcel' => 'boolean',
            'parcel_details' => 'array',
            'stops' => 'array',
            'surge_multiplier' => 'decimal:2',
            'scheduled_for' => 'datetime',
            'rating' => 'integer',
            'is_emergency_sos' => 'boolean',
        ];
    }

    public function rider()
    {
        return $this->belongsTo(Profile::class, 'rider_id');
    }

    public function driver()
    {
        return $this->belongsTo(Profile::class, 'driver_id');
    }

    public function vehicleCategory()
    {
        return $this->belongsTo(TaxiVehicleCategory::class, 'vehicle_category_id');
    }

    public function chatMessages()
    {
        return $this->hasMany(TaxiChatMessage::class, 'ride_id');
    }
}
