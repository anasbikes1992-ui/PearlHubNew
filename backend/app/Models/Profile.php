<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class Profile extends Model
{
    use HasUuid;

    protected $fillable = [
        'id',
        'full_name',
        'email',
        'phone',
        'role',
        'avatar_url',
        'nic',
        'verified',
        'verification_badges',
        'provider_tier',
        'sltda_number',
        'total_bookings',
        'avg_rating',
        'preferred_language',
    ];

    protected function casts(): array
    {
        return [
            'verified' => 'boolean',
            'verification_badges' => 'array',
            'total_bookings' => 'integer',
            'avg_rating' => 'decimal:2',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'id', 'id');
    }

    public function staysListings()
    {
        return $this->hasMany(StaysListing::class, 'user_id');
    }

    public function vehiclesListings()
    {
        return $this->hasMany(VehiclesListing::class, 'user_id');
    }

    public function eventsListings()
    {
        return $this->hasMany(EventsListing::class, 'user_id');
    }

    public function propertiesListings()
    {
        return $this->hasMany(PropertiesListing::class, 'user_id');
    }

    public function smeBusinesses()
    {
        return $this->hasMany(SmeBusiness::class, 'user_id');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class, 'user_id');
    }

    public function reviews()
    {
        return $this->hasMany(Review::class, 'user_id');
    }

    public function earnings()
    {
        return $this->hasMany(Earning::class, 'provider_id');
    }

    public function walletTransactions()
    {
        return $this->hasMany(WalletTransaction::class, 'user_id');
    }

    public function pearlPoints()
    {
        return $this->hasOne(PearlPoint::class, 'user_id');
    }
}
