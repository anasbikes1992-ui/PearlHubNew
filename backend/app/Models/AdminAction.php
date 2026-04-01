<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class AdminAction extends Model
{
    use HasUuid;

    protected $fillable = [
        'admin_id',
        'action',
        'target_table',
        'target_id',
        'note',
    ];

    public function admin()
    {
        return $this->belongsTo(Profile::class, 'admin_id');
    }
}
