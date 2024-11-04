<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Driver;
use App\Models\user_Request;
use App\Models\RidePrice;
use Illuminate\Foundation\Testing\RefreshDatabase;

class DriverRequestTest extends TestCase
{
    use RefreshDatabase;

    protected $driver;
    protected $user;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->driver = Driver::factory()->create([
            'uid' => 'driver_token_123',
            'car_type' => 'truck',
            'is_online' => true
        ]);
    }

    public function test_start_searching()
    {
        $response = $this->postJson('/driver/handle-request', [
            'token' => 'driver_token_123',
            'latitude' => '12.345',
            'longitude' => '67.890'
        ]);

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'message',
                    'current_status',
                    'driver_request'
                ]);

        $this->assertDatabaseHas('driver_requests', [
            'driver_id' => $this->driver->id,
            'status' => 'pending'
        ]);
    }

    public function test_get_available_requests()
    {
        // Create a pending user request
        $userRequest = user_Request::create([
            'user_id' => 1,
            'from' => 'Location A',
            'destination' => 'Location B',
            'material_type' => 'furniture',
            'car_type' => 'truck',
            'status' => 'pending'
        ]);

        $response = $this->postJson('/driver/handle-request', [
            'token' => 'driver_token_123',
            'latitude' => '12.345',
            'longitude' => '67.890'
        ]);

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'requests' => [
                        '*' => [
                            'request_id',
                            'from',
                            'destination',
                            'material_type'
                        ]
                    ]
                ]);
    }

    public function test_accept_ride()
    {
        // Create a pending user request
        $userRequest = user_Request::create([
            'user_id' => 1,
            'from' => 'Location A',
            'destination' => 'Location B',
            'status' => 'pending'
        ]);

        $response = $this->postJson('/driver/handle-request', [
            'token' => 'driver_token_123',
            'user_request_id' => $userRequest->id,
            'price' => 50.00,
            'latitude' => '12.345',
            'longitude' => '67.890'
        ]);

        $response->assertStatus(200)
                ->assertJson([
                    'message' => 'Ride accepted successfully'
                ]);

        $this->assertDatabaseHas('ride_prices', [
            'request_id' => $userRequest->id,
            'driver_id' => $this->driver->id,
            'price' => 50.00
        ]);
    }

    public function test_update_location()
    {
        $response = $this->postJson('/driver/handle-request', [
            'token' => 'driver_token_123',
            'latitude' => '12.345',
            'longitude' => '67.890'
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('drivers', [
            'id' => $this->driver->id,
            'latitude' => '12.345',
            'longitude' => '67.890',
            'is_online' => true
        ]);
    }

    public function test_driver_goes_offline_after_inactivity()
    {
        // Update last_active to more than timeout period ago
        $this->driver->update([
            'last_active' => now()->subMinutes(6)
        ]);

        $this->postJson('/driver/handle-request', [
            'token' => 'driver_token_123',
            'latitude' => '12.345',
            'longitude' => '67.890'
        ]);

        // Check other drivers are set offline
        $this->assertDatabaseHas('drivers', [
            'id' => $this->driver->id,
            'is_online' => false
        ]);
    }
} 