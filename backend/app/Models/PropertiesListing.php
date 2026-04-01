<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class PropertiesListing extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'property_type',
        'listing_type',
        'price',
        'location',
        'lat',
        'lng',
        'bedrooms',
        'bathrooms',
        'area_sqft',
        'features',
        'images',
        'moderation_status',
        'admin_note',
        'active',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'lat' => 'decimal:8',
            'lng' => 'decimal:8',
            'bedrooms' => 'integer',
            'bathrooms' => 'integer',
            'area_sqft' => 'decimal:2',
            'features' => 'array',
            'images' => 'array',
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
            ->where('listing_type', 'property');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class, 'listing_id')
            ->where('listing_type', 'property');
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
