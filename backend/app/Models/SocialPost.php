<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class SocialPost extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'content',
        'images',
        'likes_count',
        'comments_count',
    ];

    protected function casts(): array
    {
        return [
            'images' => 'array',
            'likes_count' => 'integer',
            'comments_count' => 'integer',
        ];
    }

    public function user()
    {
        return $this->belongsTo(Profile::class, 'user_id');
    }
}
