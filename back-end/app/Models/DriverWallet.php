<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverWallet extends Model
{
    protected $table = 'Driverwallets';
    
    protected $fillable = ['driver_id', 'balance'];
    //
}
