<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RidePrice extends Model
{
    protected $fillable = ['request_id', 'driver_id', 'price'];

    public function request()
    {
        return $this->belongsTo(user_Request::class, 'request_id');
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }
} 