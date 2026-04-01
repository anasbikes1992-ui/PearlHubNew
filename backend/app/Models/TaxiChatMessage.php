<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TaxiChatMessage extends Model
{
    use HasUuid;

    public $timestamps = false;

    protected $fillable = [
        'ride_id',
        'sender_id',
        'content',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function ride()
    {
        return $this->belongsTo(TaxiRide::class, 'ride_id');
    }

    public function sender()
    {
        return $this->belongsTo(Profile::class, 'sender_id');
    }
}
