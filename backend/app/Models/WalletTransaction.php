<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class WalletTransaction extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'type',
        'amount',
        'description',
        'status',
        'ref',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
        ];
    }

    public function user()
    {
        return $this->belongsTo(Profile::class, 'user_id');
    }
}
