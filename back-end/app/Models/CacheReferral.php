<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CacheReferral extends Model
{
    use HasFactory;

    protected $fillable = ['phone', 'referrer_id'];
}
