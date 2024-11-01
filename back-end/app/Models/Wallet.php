<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    protected $fillable = ['user_id', 'balance'];

    public function user()
    {
        return $this->belongsTo(User::class); // Adjust if using Driver model as well
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}