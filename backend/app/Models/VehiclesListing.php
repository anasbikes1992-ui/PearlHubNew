<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class VehiclesListing extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'vehicle_type',
        'brand',
        'model',
        'year',
        'price_per_day',
        'location',
        'lat',
        'lng',
        'features',
        'images',
        'available',
        'moderation_status',
        'admin_note',
        'active',
    ];

    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'price_per_day' => 'decimal:2',
            'lat' => 'decimal:8',
            'lng' => 'decimal:8',
            'features' => 'array',
            'images' => 'array',
            'available' => 'boolean',
            'active' => 'boolean',
        ];
    }

    public function owner()
    {
        return $this->belongsTo(Profile::class, 'user_id');
    }

    public function reviews()
    {
        return $this->hasMany(Review::class, 'listing_id')
            ->where('listing_type', 'vehicle');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class, 'listing_id')
            ->where('listing_type', 'vehicle');
    }

    public function scopeApproved($query)
    {
        return $query->where('moderation_status', 'approved');
    }

    public function scopeActive($query)
    {
        return $query->where('active', true);
    }

    public function scopePending($query)
    {
        return $query->where('moderation_status', 'pending');
    }
}
