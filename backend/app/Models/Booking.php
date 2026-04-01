<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'provider_id',
        'listing_id',
        'listing_type',
        'check_in',
        'check_out',
        'guests',
        'total_price',
        'status',
        'payment_status',
        'payment_method',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'check_in' => 'date',
            'check_out' => 'date',
            'guests' => 'integer',
            'total_price' => 'decimal:2',
        ];
    }

    public function user()
    {
        return $this->belongsTo(Profile::class, 'user_id');
    }

    public function provider()
    {
        return $this->belongsTo(Profile::class, 'provider_id');
    }

    public function earning()
    {
        return $this->hasOne(Earning::class, 'booking_id');
    }

    public function review()
    {
        return $this->hasOne(Review::class, 'listing_id', 'listing_id');
    }
}
