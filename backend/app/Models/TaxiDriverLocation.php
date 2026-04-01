<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TaxiDriverLocation extends Model
{
    use HasUuid;

    public $timestamps = false;

    protected $fillable = [
        'driver_id',
        'lat',
        'lng',
        'is_online',
        'vehicle_category',
    ];

    protected function casts(): array
    {
        return [
            'lat' => 'decimal:8',
            'lng' => 'decimal:8',
            'is_online' => 'boolean',
            'updated_at' => 'datetime',
        ];
    }

    public function driver()
    {
        return $this->belongsTo(Profile::class, 'driver_id');
    }
}
