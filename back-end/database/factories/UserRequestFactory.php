<?php

namespace Database\Factories;

use App\Models\user_Request;
use Illuminate\Database\Eloquent\Factories\Factory;

class UserRequestFactory extends Factory
{
    protected $model = user_Request::class;

    public function definition()
    {
        return [
            'user_id' => \App\Models\User::factory(),
            'from' => $this->faker->address,
            'destination' => $this->faker->address,
            'material_type' => $this->faker->randomElement(['Furniture', 'Electronics', 'Documents']),
            'car_type' => $this->faker->randomElement(['Truck', 'Van', 'Car']),
            'status' => 'pending',
            'latitude' => $this->faker->latitude,
            'longitude' => $this->faker->longitude,
            'accepted_driver_ids' => '[]',
            'created_at' => now(),
            'expires_at' => now()->addMinutes(5)
        ];
    }
} 