<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class driver_requests extends Model
{
    use HasFactory;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'driver_requests';

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'driver_id',
        'location',
        'car_type',
        'status',
        'RideRequest',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array
     */
    protected $casts = [
        'RideRequest' => 'array', // Cast JSON field to array
    ];

    /**
     * Relationship: DriverRequest belongs to a Driver.
     */
    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }


    /**
     * Scope to filter requests by status.
     */
    public function scopeByStatus($query, $status)
    {
        return $query->where('status', $status);
    }
}
