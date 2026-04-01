<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class PearlPoint extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'total_earned',
        'total_redeemed',
    ];

    protected function casts(): array
    {
        return [
            'total_earned' => 'integer',
            'total_redeemed' => 'integer',
        ];
    }

    public function getBalanceAttribute(): int
    {
        return $this->total_earned - $this->total_redeemed;
    }

    protected $appends = ['balance'];

    public function user()
    {
        return $this->belongsTo(Profile::class, 'user_id');
    }
}
