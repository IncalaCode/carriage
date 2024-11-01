<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    protected $table = 'wallets';
    protected $fillable = ['user_id', 'balance', 'driver_id'];

    public function user()
    {
        return $this->belongsTo(User::class); // Adjust if using Driver model as well
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }
}
