<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class Earning extends Model
{
    use HasUuid;

    protected $fillable = [
        'provider_id',
        'booking_id',
        'amount',
        'currency',
        'commission',
        'net_amount',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'commission' => 'decimal:2',
            'net_amount' => 'decimal:2',
        ];
    }

    public function provider()
    {
        return $this->belongsTo(Profile::class, 'provider_id');
    }

    public function booking()
    {
        return $this->belongsTo(Booking::class, 'booking_id');
    }
}
