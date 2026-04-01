<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class SmeProduct extends Model
{
    use HasUuid;

    protected $fillable = [
        'business_id',
        'user_id',
        'name',
        'description',
        'price',
        'currency',
        'quantity_available',
        'images',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'quantity_available' => 'integer',
            'images' => 'array',
            'is_active' => 'boolean',
        ];
    }

    public function business()
    {
        return $this->belongsTo(SmeBusiness::class, 'business_id');
    }

    public function owner()
    {
        return $this->belongsTo(Profile::class, 'user_id');
    }
}
