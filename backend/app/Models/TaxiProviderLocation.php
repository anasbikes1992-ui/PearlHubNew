<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TaxiProviderLocation extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';
    protected $primaryKey = 'provider_id';
    public $timestamps = false;

    protected $fillable = [
        'provider_id',
        'lat',
        'lng',
        'is_online',
        'updated_at',
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

    public function provider()
    {
        return $this->belongsTo(Profile::class, 'provider_id');
    }
}
