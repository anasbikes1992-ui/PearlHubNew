<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TaxiKycDocument extends Model
{
    use HasUuid;

    public $timestamps = false;

    protected $fillable = [
        'provider_id',
        'nic_number',
        'license_number',
        'nic_front_url',
        'nic_back_url',
        'license_front_url',
        'license_back_url',
        'verification_status',
        'admin_notes',
        'submitted_at',
        'verified_at',
    ];

    protected function casts(): array
    {
        return [
            'submitted_at' => 'datetime',
            'verified_at' => 'datetime',
        ];
    }

    public function provider()
    {
        return $this->belongsTo(Profile::class, 'provider_id');
    }
}
