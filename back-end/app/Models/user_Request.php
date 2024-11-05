<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class user_Request extends Model
{
    use HasFactory;

    protected $table = 'user_requests'; // Table name

    // Mass assignable fields
    protected $fillable = [
        'user_id',
        'from',
        'destination',
        'material_type',
        'car_type',
        'accepted_driver_id',
        'locked_drivers',
        'status',
    ];

    // Cast fields to specific types
    protected $casts = [
        'status' => 'string',
    ];

}