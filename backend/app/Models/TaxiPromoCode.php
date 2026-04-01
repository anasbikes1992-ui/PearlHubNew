<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TaxiPromoCode extends Model
{
    use HasUuid;

    protected $fillable = [
        'code',
        'discount_type',
        'discount_amount',
        'max_uses',
        'uses_count',
        'valid_until',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'discount_amount' => 'decimal:2',
            'max_uses' => 'integer',
            'uses_count' => 'integer',
            'valid_until' => 'datetime',
            'is_active' => 'boolean',
        ];
    }
}
