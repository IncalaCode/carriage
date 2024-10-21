<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserRequest extends Model
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
        'locked_drivers' => 'array',  // JSON field should be cast to an array
        'status' => 'string',
    ];

    /**
     * Get the user that owns the request.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the driver that accepted the request.
     */
    public function acceptedDriver()
    {
        return $this->belongsTo(Driver::class, 'accepted_driver_id');
    }
}