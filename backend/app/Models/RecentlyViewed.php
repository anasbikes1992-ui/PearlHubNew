<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class RecentlyViewed extends Model
{
    use HasUuid;

    protected $table = 'recently_viewed';

    protected $fillable = [
        'user_id',
        'listing_id',
        'listing_type',
    ];

    public function user()
    {
        return $this->belongsTo(Profile::class, 'user_id');
    }
}
