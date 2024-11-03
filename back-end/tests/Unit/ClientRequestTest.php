<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\User;
use App\Models\user_Request;
use App\Models\Driver;
use App\Models\driverRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;

class ClientRequestTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $token;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Bypass auth middleware for testing
        Route::middleware('auth')->post('/client/handle-request', [client_request::class, 'handleRequest']);
        
        // Create test user
        $this->user = User::factory()->create();
        $this->token = $this->user->uid;
    }

    public function test_create_ride_request()
    {
        $requestData = [
            'token' => $this->token,
            'action' => 'create',
            'from' => 'Test Location A',
            'destination' => 'Test Location B',
            'material_type' => 'Furniture',
            'car_type' => 'Truck',
            'latitude' => '12.9716',
            'longitude' => '77.5946'
        ];

        $response = $this->postJson('/api/client/handle-request', $requestData);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'status',
                'code',
                'data' => [
                    'request_id',
                    'timestamp',
                    'request_details',
                    'matching_drivers',
                    'expires_at',
                    'next_steps'
                ],
                'message'
            ]);
    }

    public function test_cancel_ride_request()
    {
        // Create a pending ride request
        $rideRequest = user_Request::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'pending'
        ]);

        $response = $this->postJson('/api/client/handle-request', [
            'token' => $this->token,
            'action' => 'cancel'
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'message',
                'request_id',
                'timestamp',
                'cancellation_details'
            ]);

        $this->assertEquals('cancelled', $rideRequest->fresh()->status);
    }

    public function test_update_ride_request()
    {
        $rideRequest = user_Request::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'pending'
        ]);

        $updateData = [
            'token' => $this->token,
            'action' => 'update',
            'from' => 'Updated Location A',
            'destination' => 'Updated Location B'
        ];

        $response = $this->postJson('/api/client/handle-request', $updateData);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'code',
                'data' => [
                    'message',
                    'ride_details'
                ],
                'message'
            ]);

        $updatedRequest = $rideRequest->fresh();
        $this->assertEquals('Updated Location A', $updatedRequest->from);
        $this->assertEquals('Updated Location B', $updatedRequest->destination);
    }

    public function test_get_driver_location()
    {
        $driver = Driver::factory()->create();
        $rideRequest = user_Request::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'locked',
            'locked_driver_id' => $driver->id
        ]);

        $response = $this->postJson('/api/client/handle-request', [
            'token' => $this->token
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'request_id',
                'timestamp',
                'driver_details' => [
                    'driver_id',
                    'name',
                    'car_type',
                    'rating',
                    'location',
                    'estimated_arrival'
                ],
                'ride_status'
            ]);
    }

    public function test_unauthorized_access()
    {
        $response = $this->postJson('/api/client/handle-request', [
            'token' => 'invalid_token',
            'action' => 'create'
        ]);

        $response->assertStatus(401);
    }
} 