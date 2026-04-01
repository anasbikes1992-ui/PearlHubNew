<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TaxiVehicleCategory extends Model
{
    use HasUuid;

    protected $fillable = [
        'name',
        'is_active',
        'default_seats',
        'base_fare',
        'per_km_rate',
        'icon',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'default_seats' => 'integer',
            'base_fare' => 'decimal:2',
            'per_km_rate' => 'decimal:2',
        ];
    }

    public function rides()
    {
        return $this->hasMany(TaxiRide::class, 'vehicle_category_id');
    }
}
