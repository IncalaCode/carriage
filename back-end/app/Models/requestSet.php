<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RideRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'from_location',
        'to_location',
        'material_type',
        'car_type',
        'status',
    ];

    // Cast the driver_ids field to an array
    protected $casts = [
        'driver_ids' => 'array',
    ];
}
