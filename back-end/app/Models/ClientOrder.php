<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ClientOrder extends Model
{
    use HasFactory;
    protected $table = 'client_orders';

    // Specify the fillable attributes
    protected $fillable = [
        'user_id',
        'tx_ref',
        'amount',
        'status',
    ];

    // Other model methods and relationships...
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}