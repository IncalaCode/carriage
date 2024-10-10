<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class Admin extends Authenticatable
{
    use HasFactory, Notifiable;

    // Specify the table name (optional if your table name is 'admins')
    protected $table = 'admins';

    // Specify which attributes can be mass-assigned
    protected $fillable = [
        'email',
        'password',
    ];

    // Hidden attributes (don't include these in array or JSON responses)
    protected $hidden = [
        'password',
        'remember_token',
    ];

    // Attribute casting
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    // You can add any additional methods or relationships here
}