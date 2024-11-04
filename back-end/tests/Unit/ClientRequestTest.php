<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\User;
use App\Models\Driver;
use App\Models\user_Request;
use App\Models\RidePrice;
use App\Models\RequestStatus;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ClientRequestTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $driver;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Create test user
        $this->user = User::factory()->create([
            'uid' => 'test_token_123'
        ]);

        // Create test driver
        $this->driver = Driver::factory()->create([
            'is_online' => true,
            'car_type' => 'truck'
        ]);
    }

    public function test_create_request()
    {
        $response = $this->postJson('/client/handle-request', [
            'token' => 'test_token_123',
            'from' => 'Location A',
            'destination' => 'Location B',
            'material_type' => 'furniture',
            'car_type' => 'truck',
            'latitude' => '12.345',
            'longitude' => '67.890'
        ]);

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'message',
                    'request' => [
                        'id',
                        'status',
                        'from',
                        'destination'
                    ]
                ]);

        $this->assertDatabaseHas('user_requests', [
            'user_id' => $this->user->id,
            'status' => 'pending'
        ]);
    }

    public function test_cannot_create_multiple_active_requests()
    {
        // Create an active request
        user_Request::create([
            'user_id' => $this->user->id,
            'from' => 'Location A',
            'destination' => 'Location B',
            'material_type' => 'furniture',
            'car_type' => 'truck',
            'status' => 'pending'
        ]);

        $response = $this->postJson('/client/handle-request', [
            'token' => 'test_token_123',
            'from' => 'New Location',
            'destination' => 'New Destination',
            'material_type' => 'furniture',
            'car_type' => 'truck',
            'latitude' => '12.345',
            'longitude' => '67.890'
        ]);

        $response->assertStatus(303)
                ->assertJsonStructure([
                    'message',
                    'current_request',
                    'next_action'
                ]);
    }

    public function test_get_available_drivers()
    {
        // Create a pending request
        $request = user_Request::create([
            'user_id' => $this->user->id,
            'from' => 'Location A',
            'destination' => 'Location B',
            'status' => 'pending',
            'accepted_driver_ids' => [$this->driver->id]
        ]);

        // Create a price offer
        RidePrice::create([
            'request_id' => $request->id,
            'driver_id' => $this->driver->id,
            'price' => 50.00
        ]);

        $response = $this->postJson('/client/handle-request', [
            'token' => 'test_token_123'
        ]);

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'drivers' => [
                        '*' => [
                            'driver_id',
                            'name',
                            'car_type',
                            'price'
                        ]
                    ]
                ]);
    }

    public function test_update_request()
    {
        // Create a pending request
        $request = user_Request::create([
            'user_id' => $this->user->id,
            'from' => 'Location A',
            'destination' => 'Location B',
            'status' => 'pending'
        ]);

        $response = $this->postJson('/client/handle-request', [
            'token' => 'test_token_123',
            'update' => true,
            'from' => 'Updated Location',
            'destination' => 'Updated Destination'
        ]);

        $response->assertStatus(200)
                ->assertJson([
                    'message' => 'Request updated successfully'
                ]);

        $this->assertDatabaseHas('user_requests', [
            'id' => $request->id,
            'from' => 'Updated Location',
            'destination' => 'Updated Destination'
        ]);
    }
} 