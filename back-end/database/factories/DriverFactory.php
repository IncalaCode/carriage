<?php

namespace Database\Factories;

use App\Models\Driver;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class DriverFactory extends Factory
{
    protected $model = Driver::class;

    public function definition()
    {
        return [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
            'phone' => $this->faker->phoneNumber,
            'uid' => Str::random(32),
            'car_type' => $this->faker->randomElement(['Truck', 'Van', 'Car']),
            'rating' => $this->faker->randomFloat(1, 3, 5),
            'total_rides' => $this->faker->numberBetween(0, 1000),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
