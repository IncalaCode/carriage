<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class DriverTransactionRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'driver_request_id', // Foreign key to driver request
        'user_id',           // Foreign key to user (driver)
        'amount',
        'tx_ref',
        'type',
        'status',
        'description',
    ];

    // Relationship with DriverRequest model
    public function driverRequest()
    {
        return $this->belongsTo(DriverRequest::class);
    }

    // Relationship with User model (driver)
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}