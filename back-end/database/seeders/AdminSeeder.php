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
        // Driver::create([
        //     'first_name' => 'required|string|max:255',
        //     'last_name' => 'required|string|max:255',
        //     'phone_number' => 'required',
        //     'driver_id' => 'required|string|max:255',
        //     'id_card_image_path' => 'required|image|max:2048',
        //     'password' => 'required|string|min:8|confirmed'
        // ]);
    }
    
}