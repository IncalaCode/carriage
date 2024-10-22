<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Driver extends Model
{
    use HasFactory;

    protected $table = 'drivers'; // Table name

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

    /**
     * Get the user that was accepted by the driver.
     */
    public function acceptedUser()
    {
        return $this->belongsTo(User::class, 'accepted_user_id');
    }

    /**
     * Get the user requests associated with the driver.
     */
    public function userRequests()
    {
        return $this->hasMany(UserRequest::class, 'accepted_driver_id');
    }
}