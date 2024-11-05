<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RidePrice extends Model
{
    protected $fillable = ['request_id', 'driver_id', 'price'];

} 