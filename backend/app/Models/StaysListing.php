<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class StaysListing extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'stay_type',
        'stars',
        'price_per_night',
        'location',
        'lat',
        'lng',
        'rooms',
        'amenities',
        'images',
        'approved',
        'moderation_status',
        'active',
        'admin_notes',
    ];

    protected function casts(): array
    {
        return [
            'stars' => 'integer',
            'price_per_night' => 'decimal:2',
            'lat' => 'decimal:8',
            'lng' => 'decimal:8',
            'rooms' => 'integer',
            'amenities' => 'array',
            'images' => 'array',
            'approved' => 'boolean',
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
            ->where('listing_type', 'stay');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class, 'listing_id')
            ->where('listing_type', 'stay');
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
