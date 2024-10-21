<?php

namespace Database\Seeders;  // Add this line

use Illuminate\Database\Seeder;
use App\Models\Admin;
use Illuminate\Support\Facades\Hash;
use App\Models\Driver;

class AdminSeeder extends Seeder
{
    public function run()
    {
        Admin::create([
            'email' => 'admin@example.com',
            'password' => Hash::make('password123'),
        ]);
    }
    
}