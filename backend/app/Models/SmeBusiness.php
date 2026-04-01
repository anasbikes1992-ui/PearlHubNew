<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class SmeBusiness extends Model
{
    use HasUuid;

    protected $table = 'sme_businesses';

    protected $fillable = [
        'user_id',
        'business_name',
        'description',
        'category',
        'location',
        'lat',
        'lng',
        'phone',
        'email',
        'website',
        'images',
        'verified',
        'moderation_status',
        'active',
        'admin_notes',
    ];

    protected function casts(): array
    {
        return [
            'lat' => 'decimal:8',
            'lng' => 'decimal:8',
            'images' => 'array',
            'verified' => 'boolean',
            'active' => 'boolean',
        ];
    }

    public function owner()
    {
        return $this->belongsTo(Profile::class, 'user_id');
    }

    public function products()
    {
        return $this->hasMany(SmeProduct::class, 'business_id');
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
