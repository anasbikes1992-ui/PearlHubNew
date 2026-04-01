<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class Referral extends Model
{
    use HasUuid;

    protected $fillable = [
        'referrer_id',
        'referred_id',
        'referral_code',
        'status',
        'reward_lkr',
    ];

    protected function casts(): array
    {
        return [
            'reward_lkr' => 'decimal:2',
        ];
    }

    public function referrer()
    {
        return $this->belongsTo(Profile::class, 'referrer_id');
    }

    public function referred()
    {
        return $this->belongsTo(Profile::class, 'referred_id');
    }
}
