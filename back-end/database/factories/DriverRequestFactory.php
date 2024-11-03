<?php

namespace Database\Factories;

use App\Models\driverRequest;
use Illuminate\Database\Eloquent\Factories\Factory;

class DriverRequestFactory extends Factory
{
    protected $model = driverRequest::class;

    public function definition()
    {
        return [
            'driver_id' => \App\Models\Driver::factory(),
            'longitude' => $this->faker->longitude,
            'latitude' => $this->faker->latitude,
            'car_type' => $this->faker->randomElement(['Truck', 'Van', 'Car']),
            'status' => 'pending',
            'is_online' => true,
            'last_active' => now(),
            'accepted_user_ids' => '[]',
            'max_requests' => 3,
            'preferences' => json_encode([
                'material_types' => ['Furniture', 'Electronics'],
                'max_distance' => 10
            ])
        ];
    }
} 