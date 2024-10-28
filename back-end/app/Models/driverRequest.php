<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class driverRequest extends Model
{
    use HasFactory;

    protected $table = 'driverRequest'; // Table name

    // Mass assignable fields
    protected $fillable = [
        'driver_id',
        'longitude',
        'latitude',
        'car_type',
        'status',
        'accepted_user_id',
        'locked_user_ids',
    ];

    // Cast fields to specific types
    protected $casts = [
        'locked_user_ids' => 'array',  // JSON field should be cast to an array
        'status' => 'string',
        'longitude' => 'float',
        'latitude' => 'float',
    ];

}