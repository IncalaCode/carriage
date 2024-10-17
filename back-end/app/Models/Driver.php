<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;

class Driver extends Authenticatable
{
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'first_name',
        'last_name',
        'phone_number',
        'password',
        'verified',
        'driver_id', // Include this as it's in your migration.
        'id_card_image_path',
        'car_type',
        'driver_license_photo',
        'car_plate_photo',
        'user_photo',
        'uid', // Include this as well based on your schema.
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'password' => 'hashed',
        'verified' => 'boolean', // Cast the verified attribute to a boolean.
    ];

    /**
     * Indicates if the model should be timestamped.
     *
     * @var bool
     */
    public $timestamps = true; // This will use created_at and updated_at by default. Remove if not needed.

    /**
     * If you are using the driver as an authenticatable user,
     * you might want to set the guard for the Driver model.
     * This is optional and based on your application needs.
     */
    protected $table = 'drivers'; // Optional: Specify the table name if it's not the plural of the model name.


    // Add any additional methods or relationships as needed.
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($driver) {
            $driver->uid = Str::uuid(); // Automatically generate a UUID for new drivers
        });
    }
}
